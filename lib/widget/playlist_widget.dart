// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:ztv/model/play_list_info.dart';
import 'package:ztv/model/playlist.dart';

import '../model/isolate_model.dart';
import '../util/util.dart';
import 'channel.dart';

class PlaylistWidget extends StatefulWidget {
  final Function _onTap;

  final double _offset;

  String? _query;
  final String? _playlistLink;
  final bool _hasSavePlayList;
  final String? _lans;
  final Database _db;
  PlaylistInfo _info;
  final Function(PlaylistInfo) _onSetInfo;

  PlaylistWidget(this._lans, this._onTap, this._offset, this._query, this._playlistLink, this._hasSavePlayList, this._db,
      this._info, this._onSetInfo,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlaylistWidgetState();
}

late Function onTap;

class _PlaylistWidgetState extends State<PlaylistWidget> {
  static const TAG = '_PlaylistState';
  late ScrollController _scrollController;
  var showSearchView = false;
  var ctr;
  bool linkBroken = false;

  @override
  void initState() {
    _scrollController = ScrollController(initialScrollOffset: widget._offset);
    ctr = TextEditingController(text: widget._query);
    onTap = widget._onTap;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var searchActive = showSearchView || (widget._query != null && widget._query?.isNotEmpty == true);
    return Scaffold(
        appBar: AppBar(leading: const BackButton(), actions: [
          const SizedBox(width: 48),
          Expanded(
              child: searchActive
                  ? TextField(
                      style: const TextStyle(color: Colors.white),
                      onChanged: (String txt) {
                        if (txt.trim().isNotEmpty)
                          setState(() {
                            widget._query = txt;
                          });
                      },
                      controller: ctr,
                      cursorColor: Colors.white,
                      // controller: TextEditingController(text: widget._query),
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.only(top: 16),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
                    )
                  : Container()),
          searchActive
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() {
                    showSearchView = false;
                    widget._query = null;
                    ctr = null;
                  }),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => showSearchView = true)),
          widget._info.hasFilter
              ? IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: () => dialog(
                          context,
                          (lan, cat) => setState(() {
                                widget._info.filterLanguage = lan;
                                widget._info.filterCategory = cat;
                              }), () {
                        widget._info.filterLanguage = getLocalizedLanguage(ANY_LANGUAGE, AppLocalizations.of(context));
                        widget._info.filterCategory = getLocalizedCategory(ANY_CATEGORY, AppLocalizations.of(context));
                      }))
              : const SizedBox.shrink(),
          if (widget._hasSavePlayList)
            IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: () => showDialog(context: context, builder: (_) => SaveDialog(widget._playlistLink, widget._db)))
        ]),
        body: FutureBuilder(
            future: (widget._query == null || widget._query?.isEmpty == true) &&
                    widget._info.filterLanguage == getLocalizedLanguage(ANY_LANGUAGE, AppLocalizations.of(context)) &&
                    widget._info.filterCategory == getLocalizedCategory(ANY_CATEGORY, AppLocalizations.of(context))
                ? getChannels(widget._info.linkOrList, widget._lans)
                : getFilteredChannels(getChannels(widget._info.linkOrList, widget._lans), widget._query ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.data == null) linkBroken = true;
                final w = MediaQuery.of(context).size.width;
                log(_PlaylistWidgetState.TAG, 'w=>$w');
                return linkBroken
                    ? Center(
                        child: Text(AppLocalizations.of(context)?.broken_link ?? 'Link is broken!',
                            style: const TextStyle(fontSize: 25)))
                    : GridView.count(
                        crossAxisCount: w >= 809 ? 5 : 3, children: snapshot.data as List<Widget>, controller: _scrollController);
              } else
                return const Center(child: CircularProgressIndicator());
            }));
  }

  Future<List<Channel>> getChannels(link, lans) async {
    log(_PlaylistWidgetState.TAG, 'get channels');
    if (link is List<Channel>) {
      log(_PlaylistWidgetState.TAG, 'link is list');
      var t1 = time;
      for (final ch in link) {
        ch.filterLanguage = widget._info.filterLanguage;
        ch.filterCategory = widget._info.filterCategory;
        _setSC(ch);
      }
      var t2 = time;
      log(_PlaylistWidgetState.TAG, 'iteration time=>${t2 - t1}');
      return Future.value(link);
    } else if (link.startsWith('/')) return Future.value(fileToPlaylist(link));
    final fList = <Future<http.Response>>[];
    fList.add(http.get(Uri.parse(widget._info.linkOrList)));
    const utf8decoder = Utf8Decoder();
    List<Channel>? channelsWithLans;
    if (lans != null) fList.add(http.get(Uri.parse(lans)));
    final t1 = time;
    final fResultList = await Future.wait(fList);
    if (fResultList.first.statusCode == 404) {
      linkBroken = true;
      return Future.value(null);
    }
    if (fResultList.length == 2)
      channelsWithLans = await compute(
          parseLans,
          IsolateModel(
              const [], utf8decoder.convert(fResultList.last.bodyBytes), PlaylistInfo(), false, AppLocalizations.of(context)));

    final model = IsolateModel(channelsWithLans ?? const [], utf8decoder.convert(fResultList.first.bodyBytes), widget._info,
        widget._hasSavePlayList, AppLocalizations.of(context));
    late PlaylistInfo info;
    try {
      info = await compute(parse, model);
      final t2 = time;
      log(_PlaylistWidgetState.TAG, 'tot chs comp time=>${t2 - t1}');
      widget._info = info;
      setState(() =>
          widget._info.hasFilter = (widget._info.dropDownCategories.length > 1 || widget._info.dropDownLanguages.length > 1));
    } catch (e) {
      log(TAG, 'e=>$e');
    }
    widget._onSetInfo(info);
    return info.linkOrList;
  }

  get time => DateTime.now().millisecondsSinceEpoch;

  void _setSC(Channel element) => element.sc = _scrollController;

  Future<List<Channel>> fileToPlaylist(link) => File(link).readAsString().then((value) =>
      parse(IsolateModel(const [], value, widget._info, widget._hasSavePlayList, AppLocalizations.of(context))).linkOrList
        ..forEach((_setSC)));

  Future<List<Channel>> getFilteredChannels(Future<List<Channel>> f, String q) {
    log(_PlaylistWidgetState.TAG, 'get filtered channels');
    return f.then((list) => list.where((element) {
          element.query = widget._query ?? '';
          return ((q.isEmpty) ? true : element.title.toLowerCase().contains(q.toLowerCase())) &&
              (widget._info.filterLanguage != getLocalizedLanguage(ANY_LANGUAGE, AppLocalizations.of(context))
                  ? element.languages.contains(widget._info.filterLanguage)
                  : true) &&
              (widget._info.filterCategory != getLocalizedCategory(ANY_CATEGORY, AppLocalizations.of(context))
                  ? element.categories.contains(widget._info.filterCategory)
                  : true);
        }).toList());
  }

  void dialog(ctx, submit, clear) => showDialog(
      context: ctx,
      builder: (_) => ZtvDialog(submit, clear, widget._info.filterLanguage, widget._info.filterCategory,
          widget._info.dropDownLanguages, widget._info.dropDownCategories));
}

List<Channel> parseLans(IsolateModel model) {
  final lines = model.data.split("\n");
  final locs = model.localizations;
  final list = <Channel>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('#EXTINF')) {
      final split = line.split(',');
      var title = split.last.replaceAll('====', '');
      String link = lines[++i];
      final endsWith = link.trim().endsWith('.png');
      if (endsWith || badLink(link)) continue;
      if (link.startsWith('#EXTGRP')) {
        i++;
      }
      while (!(link = lines[i]).startsWith('http')) i++;
      final channel = Channel(title, link, () {});
      var data = split.first;
      setChannelProperties(data, channel, true, locs);
      list.add(channel);
    }
  }
  return list;
}

PlaylistInfo parse(IsolateModel model) {
  log(TAG, 'parse');
  final lines = model.data.split("\n");
  final channelsWithLans = model.chs;
  final info = model.info;
  final locs = model.localizations;
  final list = <Channel>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('#EXTINF')) {
      final split = line.split(',');
      var title = split.last.replaceAll('====', '');
      String link = lines[++i];
      final endsWith = link.trim().endsWith('.png');
      if (endsWith || badLink(link)) continue;
      String? category;
      if (link.startsWith('#EXTGRP')) {
        category = link.split(':')[1];
        i++;
      }
      while (!(link = lines[i]).startsWith('http')) i++;
      final channel = Channel(
          title,
          link,
          (offset, query, language, category, logo, ch) => onTap(link, list, offset, query, language, category, title, logo,
              info.dropDownLanguages, info.dropDownCategories, info.hasFilter, () => list.remove(ch)));
      if (category != null) channel.categories.add(getLocalizedCategory(category, locs));
      if (title.contains(RegExp('FRANCE|\\|FR\\|'))) {
        channel.languages.add(getLocalizedLanguage(FRENCH, locs));
      } else if (title.contains(RegExp('\\|AR\\|'))) {
        channel.languages.add(getLocalizedLanguage(ARABIC, locs));
      } else if (title.contains(RegExp('USA|5USA'))) {
        channel.languages.add(getLocalizedLanguage(ENGLISH, locs));
      } else if (title.contains('NL')) {
        channel.languages.add(getLocalizedLanguage(DUTCH, locs));
      } else if (link.contains(RegExp('latino|\\|SP\\|'))) {
        channel.languages.add(getLocalizedLanguage(SPANISH, locs));
      } else if (title.contains(':')) {
        switch (title.split(':').first) {
          case 'FR':
            channel.languages.add(getLocalizedLanguage(FRENCH, locs));
            break;
          case 'TR':
            channel.languages.add(getLocalizedLanguage(TURKISH, locs));
            break;
        }
      }
      if (title.contains(RegExp('SPORTS?'))) {
        channel.categories.add(getLocalizedCategory(SPORTS, locs));
      } else if (title.contains('News')) {
        channel.categories.add(getLocalizedCategory(NEWS, locs));
      } else if (title.contains(RegExp('XXX|Brazzers'))) {
        channel.categories.add(XXX);
      } else if (title.contains(RegExp('BABY|CARTOON|JEUNESSE'))) {
        channel.categories.add(getLocalizedCategory(KIDS, locs));
      } else if (title.contains(RegExp('MTV|Music'))) {
        channel.categories.add(getLocalizedCategory(MUSIC, locs));
      }
      if (title.toLowerCase().contains('weather')) {
        channel.categories.add(getLocalizedCategory(WEATHER, locs));
      }
      var data = split.first;
      for (final ch in channelsWithLans)
        if (ch.url == channel.url) {
          channel.languages.addAll(ch.languages);
          channelsWithLans.remove(ch);
          break;
        }

      setChannelProperties(data, channel, false, locs);
      for (final l in channel.languages) {
        if (!info.dropDownLanguages.contains(l)) info.dropDownLanguages.add(l);
      }
      for (final c in channel.categories) {
        if (!info.dropDownCategories.contains(c)) info.dropDownCategories.add(c);
      }
      list.add(channel);
    }
  }
  info.dropDownCategories.sort();
  info.dropDownCategories.insert(0, getLocalizedCategory(ANY_CATEGORY, locs));
  info.dropDownLanguages.sort();
  info.dropDownLanguages.insert(0, getLocalizedLanguage(ANY_LANGUAGE, locs));
  info.filterCategory = getLocalizedCategory(info.filterCategory, locs);
  info.filterLanguage = getLocalizedLanguage(info.filterLanguage, locs);
  info.linkOrList = list;
  if (!(model.hasSavePlaylist)) info.myIPTVPlaylist = list;
  return info;
}

bool badLink(link) =>
    link == 'https://d15690s323oesy.cloudfront.net/v1/master/9d062541f2ff39b5c0f48b743c6411d25f62fc25/UDU-Plex/158.m3u8' ||
    link == 'https://sc.id-tv.kz/31Kanal.m3u8';

setChannelProperties(String s, Channel channel, bool forLans, locs) {
  s = s.replaceAll('#EXTINF:-1 ', '');
  var item = '';
  var quoteCount = 0;
  for (final c in s.characters) {
    if (quoteCount == 2) {
      quoteCount = 0;
      continue;
    }
    if (c == '"')
      quoteCount++;
    else
      item += c;
    if (quoteCount == 2) {
      processItem(item, channel, forLans, locs);
      item = '';
    }
  }
}

void processItem(String item, Channel channel, bool forLans, locs) {
  String str;
  if (item.startsWith(forLans ? 'group-title' : 'tvg-language') && (str = item.split('=').last).isNotEmpty) {
    channel.languages.addAll(str.split(';').map((e) => getLocalizedLanguage(e, locs)));
    if (channel.languages.contains(CASTILIAN)) {
      channel.languages.remove(CASTILIAN);
      channel.languages.add(getLocalizedLanguage(SPANISH, locs));
    } else if (channel.languages.contains(FARSI)) {
      channel.languages.remove(FARSI);
      channel.languages.add(getLocalizedLanguage(PERSIAN, locs));
    } else if (channel.languages.contains('Gernman')) {
      channel.languages.remove('Gernman');
      channel.languages.add(getLocalizedLanguage(GERMAN, locs));
    } else if (channel.languages.contains('Japan')) {
      channel.languages.remove("Japan");
      channel.languages.add(getLocalizedLanguage(JAPANESE, locs));
    } else if (channel.languages.contains('CA')) {
      channel.languages.remove('CA');
      channel.languages.add(getLocalizedLanguage(ENGLISH, locs));
    } else if (channel.languages.any((l) => l.startsWith('Mandarin'))) {
      channel.languages.removeWhere((l) => l.startsWith('Mandarin'));
      channel.languages.add(getLocalizedLanguage(CHINESE, locs));
    } else if (channel.languages.contains('Min')) {
      channel.languages.remove('Min');
      channel.languages.add(getLocalizedLanguage(CHINESE, locs));
    } else if (channel.languages.contains('Modern')) {
      channel.languages.remove('Modern');
      channel.languages.add(getLocalizedLanguage(GREEK, locs));
    } else if (channel.languages.contains('News')) {
      channel.languages.remove('News');
      channel.languages.add(getLocalizedLanguage(ENGLISH, locs));
    } else if (channel.languages.contains('Panjabi')) {
      channel.languages.remove('Panjabi');
      channel.languages.add(getLocalizedLanguage(PUNJABI, locs));
    } else if (channel.languages.contains('Western')) {
      channel.languages.remove('Western');
      channel.languages.add(getLocalizedLanguage(DUTCH, locs));
    } else if (channel.languages.any((l) => l.startsWith('Yue'))) {
      channel.languages.removeWhere((l) => l.startsWith('Yue'));
      channel.languages.add(getLocalizedLanguage(CHINESE, locs));
    } else if (channel.languages.contains('Central')) {
      channel.languages.remove('Central');
    } else if (channel.languages.contains('Dhivehi')) {
      channel.languages.remove('Dhivehi');
      channel.languages.add(getLocalizedLanguage(MALDIVIAN, locs));
    } else if (channel.languages.contains('Kirghiz')) {
      channel.languages.remove('Kirghiz');
      channel.languages.add(getLocalizedLanguage(KYRGYZ, locs));
    } else if (channel.languages.contains('Letzeburgesch')) {
      channel.languages.remove('Letzeburgesch');
      channel.languages.add(getLocalizedLanguage(LUXEMBOURGISH, locs));
    } else if (channel.languages.contains('Northern Kurdish') || channel.languages.contains('Central Kurdish')) {
      channel.languages.removeWhere((e) => e == 'Central Kurdish' || e == 'Northern Kurdish');
      channel.languages.add(getLocalizedLanguage(KURDISH, locs));
    } else if (channel.languages.contains('Assyrian Neo-Aramaic')) {
      channel.languages.remove('Assyrian Neo-Aramaic');
      channel.languages.add(getLocalizedLanguage(ASSYRIAN, locs));
    } else if (channel.languages.contains('Norwegian Bokmål')) {
      channel.languages.remove('Norwegian Bokmål');
      channel.languages.add(getLocalizedLanguage(NORWEGIAN, locs));
    } else if (channel.languages.any((l) => l.startsWith('Oriya'))) {
      channel.languages.removeWhere((l) => l.startsWith('Oriya'));
      channel.languages.add(getLocalizedLanguage(ODIA, locs));
    }
  } else if (!forLans && item.startsWith('tvg-logo') && (str = item.split('=').last).isNotEmpty) {
    channel.logo = str;
  } else if (!forLans && item.startsWith('group-title') && (str = item.split('=').last).isNotEmpty) {
    channel.categories.addAll(str.split(';').where((element) => element != UNDEFINED).map((e) => getLocalizedCategory(e, locs)));
  }
}

class SaveDialog extends StatelessWidget {
  static const TAG = 'SaveDialog';

  final String? playlistLink;
  final Database db;

  const SaveDialog(this.playlistLink, this.db, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    var name = 'Playlist_${now.year}_${now.month}_${now.day}_${now.hour}_${now.minute}_${now.second}';
    return AlertDialog(
      title: Text(AppLocalizations.of(context)?.save_playlist ?? 'Save playlist'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: TextEditingController(text: name),
            onChanged: (v) => name = v,
          ),
          if (playlistLink == null)
            Text(AppLocalizations.of(context)?.playlist_link_broken ?? "Playlist link is broken. Can't save it.",
                style: const TextStyle(color: Colors.red))
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              if (name.isEmpty || playlistLink == null) return;
              savePlaylist(Playlist(name, playlistLink!));
              Navigator.of(context).pop();
            },
            child: const Text('OK'))
      ],
    );
  }

  savePlaylist(Playlist playlist) => db.insert('playlist', playlist.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
}

class ZtvDialog extends StatefulWidget {
  final submit;
  final clear;
  var language;
  var category;
  final List<String> dropDownLanguages;
  final dropDownCategories;

  ZtvDialog(this.submit, this.clear, this.language, this.category, this.dropDownLanguages, this.dropDownCategories);

  @override
  State<StatefulWidget> createState() => DialogState();
}

class DialogState extends State<ZtvDialog> {
  static const TAG = 'DialogState';

  @override
  Widget build(BuildContext context) {
    var of = AppLocalizations.of(context);
    var languageSpinnerAndTitle = SpinnerAndTitle(widget.language, of?.language ?? 'Language', widget.dropDownLanguages);
    var categorySpinnerAndTitle = SpinnerAndTitle(widget.category, of?.category ?? 'Category', widget.dropDownCategories);
    var edgeInsetsOnlyRight2 = const EdgeInsets.only(right: 2);
    return AlertDialog(
        title: Padding(child: Text(AppLocalizations.of(context)?.filter ?? 'Filter'), padding: const EdgeInsets.only(bottom: 16)),
        contentPadding: const EdgeInsets.only(left: 4, right: 4),
        actions: [
          TextButton(
              onPressed: () => setState(() {
                    widget.language = getLocalizedLanguage(ANY_LANGUAGE, AppLocalizations.of(context));
                    widget.category = getLocalizedCategory(ANY_CATEGORY, AppLocalizations.of(context));
                    widget.clear();
                  }),
              child: Text(of?.reset ?? 'Reset')),
          TextButton(
              onPressed: () {
                widget.submit(languageSpinnerAndTitle.dropdownValue, categorySpinnerAndTitle.dropdownValue);
                Navigator.of(context).pop();
              },
              child: const Text('OK'))
        ],
        content: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(padding: edgeInsetsOnlyRight2, child: languageSpinnerAndTitle),
                Padding(padding: edgeInsetsOnlyRight2, child: categorySpinnerAndTitle)
              ],
            )));
  }
}

class SpinnerAndTitle extends StatefulWidget {
  static const TAG = 'SpinnerAndTitle';
  var dropdownValue;
  String title;
  final items;

  SpinnerAndTitle(this.dropdownValue, this.title, this.items) {
    log(TAG, 'drop down val=>$dropdownValue');
  }

  @override
  State<StatefulWidget> createState() => SpinnerAndTitleState();
}

class SpinnerAndTitleState extends State<SpinnerAndTitle> {
  static const TAG = 'SpinnerAndTitleState';

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(widget.title),
      DropdownButton<String>(
          value: widget.dropdownValue,
          onChanged: (String? newValue) {
            setState(() => widget.dropdownValue = newValue);
          },
          items: widget.items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList())
    ]);
  }
}
