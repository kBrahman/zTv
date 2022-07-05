// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:ztv/model/play_list_info.dart';
import 'package:ztv/model/playlist.dart';

import '../util/util.dart';
import 'channel.dart';

class PlaylistWidget extends StatefulWidget {
  dynamic _linkOrList;

  final Function onTap;

  final double _offset;

  String? _query;
  String _filterCategory;
  final String? _playlistLink;
  final List<String> _dropDownLanguages;
  final List<String> _dropDownCategories;
  final bool hasSavePlayList;
  final String? _xLink;
  final Database db;
  final PlaylistInfo _info;

  PlaylistWidget(this._linkOrList, this._xLink, this.onTap, this._offset, this._query, this._filterCategory, this._playlistLink,
      this._dropDownLanguages, this._dropDownCategories, this.hasSavePlayList, this.db, this._info,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlaylistWidgetState();
}

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
                              widget._filterCategory = cat;
                            }), () {
                      widget._info.filterLanguage = getLocalizedLanguage(ANY_LANGUAGE, context);
                      widget._filterCategory = getLocalizedCategory(ANY_CATEGORY, context);
                    }))
            : const SizedBox.shrink(),
        if (widget.hasSavePlayList)
          IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: () => showDialog(context: context, builder: (_) => SaveDialog(widget._playlistLink, widget.db)))
      ]),
      body: FutureBuilder(
        future: (widget._query == null || widget._query?.isEmpty == true) &&
                (widget._info.filterLanguage == getLocalizedLanguage(ANY_LANGUAGE, context)) &&
                (widget._filterCategory == getLocalizedCategory(ANY_CATEGORY, context))
            ? getChannels(widget._linkOrList, widget._xLink)
            : getFilteredChannels(getChannels(widget._linkOrList, widget._xLink), widget._query ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return linkBroken
                ? Center(
                    child: Text(AppLocalizations.of(context)?.broken_link ?? 'Link is broken!',
                        style: const TextStyle(fontSize: 25)))
                : GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width >= 834 ? 4 : 3,
                    children: snapshot.data as List<Widget>,
                    controller: _scrollController,
                  );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<List<Channel>> getChannels(link, xLink) {
    if (link is List<Channel>) {
      for (var ch in link) {
        if (ch.isOff) {
          link.remove(ch);
        } else {
          ch.filterLanguage = widget._info.filterLanguage;
          ch.filterCategory = widget._filterCategory;
          ch.sc = _scrollController;
        }
      }
      return Future.value(link);
    } else if (link.startsWith('/')) return Future.value(fileToPlaylist(link));

    return http.get(Uri.parse(widget._linkOrList)).then((value) async {
      if (value.statusCode == 404) {
        linkBroken = true;
        return Future.value(null);
      }
      const utf8decoder = Utf8Decoder();
      var data = utf8decoder.convert(value.bodyBytes);
      if (xLink != null) {
        final xData = await http.get(Uri.parse(xLink));
        data += utf8decoder.convert(xData.bodyBytes);
      }
      return parse(data);
    }, onError: (err) {
      linkBroken = true;
      Future.value(null);
    });
  }

  Future<List<Channel>> fileToPlaylist(link) => File(link).readAsString().then((value) => parse(value));

  Future<List<Channel>> parse(String data) async {
    final lines = data.split("\n");
    final list = <Channel>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('#EXTINF')) {
        final split = line.split(',');
        var title = split.last.replaceAll('====', '');
        String link = lines[++i];
        var endsWith = link.trim().endsWith('.png');
        if (endsWith) continue;
        String? category;
        if (link.startsWith('#EXTGRP')) {
          category = link.split(':')[1];
          i++;
        }
        while (!(link = lines[i]).startsWith('http')) i++;
        final channel = Channel(
            title,
            link,
            (offset, query, language, category, logo, ch) => widget.onTap(link, list, offset, query, language, category, title,
                logo, widget._dropDownLanguages, widget._dropDownCategories, widget._info.hasFilter, () => list.remove(ch)));
        channel.sc = _scrollController;
        if (category != null) channel.categories.add(getLocalizedCategory(category, context));
        if (title.contains(RegExp('FRANCE|\\|FR\\|'))) {
          channel.languages.add(getLocalizedLanguage(FRENCH, context));
        } else if (title.contains(RegExp('\\|AR\\|'))) {
          channel.languages.add(getLocalizedLanguage(ARABIC, context));
        } else if (title.contains(RegExp('USA|5USA'))) {
          channel.languages.add(getLocalizedLanguage(ENGLISH, context));
        } else if (title.contains('NL')) {
          channel.languages.add(getLocalizedLanguage(DUTCH, context));
        } else if (link.contains(RegExp('latino|\\|SP\\|'))) {
          channel.languages.add(getLocalizedLanguage(SPANISH, context));
        } else if (title.contains(':')) {
          switch (title.split(':').first) {
            case 'FR':
              channel.languages.add(getLocalizedLanguage(FRENCH, context));
              break;
            case 'TR':
              channel.languages.add(getLocalizedLanguage(TURKISH, context));
              break;
          }
        }
        if (title.contains(RegExp('SPORTS?'))) {
          channel.categories.add(getLocalizedCategory(SPORTS, context));
        } else if (title.contains('News')) {
          channel.categories.add(getLocalizedCategory(NEWS, context));
        } else if (title.contains(RegExp('XXX|Brazzers'))) {
          channel.categories.add(XXX);
        } else if (title.contains(RegExp('BABY|CARTOON|JEUNESSE'))) {
          channel.categories.add(getLocalizedCategory(KIDS, context));
        } else if (title.contains(RegExp('MTV|Music'))) {
          channel.categories.add(getLocalizedCategory(MUSIC, context));
        }
        if (title.toLowerCase().contains('weather')) {
          channel.categories.add(getLocalizedCategory(WEATHER, context));
        }
        var data = split.first;
        setChannelProperties(data, channel);
        for (final l in channel.languages) {
          if (!widget._dropDownLanguages.contains(l)) widget._dropDownLanguages.add(l);
        }
        for (final c in channel.categories) {
          if (!widget._dropDownCategories.contains(c)) widget._dropDownCategories.add(c);
        }
        list.add(channel);
      }
    }
    widget._dropDownCategories.sort();
    widget._dropDownCategories.insert(0, getLocalizedCategory(ANY_CATEGORY, context));
    widget._dropDownLanguages.sort();
    widget._dropDownLanguages.insert(0, getLocalizedLanguage(ANY_LANGUAGE, context));
    widget._filterCategory = getLocalizedCategory(widget._filterCategory, context);
    widget._info.filterLanguage = getLocalizedLanguage(widget._info.filterLanguage, context);
    setState(() => widget._info.hasFilter = (widget._dropDownCategories.length > 1 || widget._dropDownLanguages.length > 1));
    widget._linkOrList = list;
    if (!widget.hasSavePlayList) widget._info.myIPTVPlaylist = list;
    return Future.value(list);
  }

  Future<List<Channel>> getFilteredChannels(Future<List<Channel>> f, String q) {
    return f.then((list) => list.where((element) {
          element.query = widget._query ?? '';
          return ((q.isEmpty) ? true : element.title.toLowerCase().contains(q.toLowerCase())) &&
              (widget._info.filterLanguage != getLocalizedLanguage(ANY_LANGUAGE, context)
                  ? element.languages.contains(widget._info.filterLanguage)
                  : true) &&
              (widget._filterCategory != getLocalizedCategory(ANY_CATEGORY, context)
                  ? element.categories.contains(widget._filterCategory)
                  : true);
        }).toList());
  }

  void dialog(ctx, submit, clear) => showDialog(
      context: ctx,
      builder: (_) => ZtvDialog(submit, clear, widget._info.filterLanguage, widget._filterCategory, widget._dropDownLanguages,
          widget._dropDownCategories));

  setChannelProperties(String s, Channel channel) {
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
        processItem(item, channel);
        item = '';
      }
    }
  }

  void processItem(String item, Channel channel) {
    String str;
    if (item.startsWith('tvg-language') && (str = item.split('=').last).isNotEmpty) {
      channel.languages.addAll(str.split(';').map((e) => getLocalizedLanguage(e, context)));
      if (channel.languages.contains(CASTILIAN)) {
        channel.languages.remove(CASTILIAN);
        channel.languages.add(getLocalizedLanguage(SPANISH, context));
      } else if (channel.languages.contains(FARSI)) {
        channel.languages.remove(FARSI);
        channel.languages.add(getLocalizedLanguage(PERSIAN, context));
      } else if (channel.languages.contains('Gernman')) {
        channel.languages.remove('Gernman');
        channel.languages.add(getLocalizedLanguage(GERMAN, context));
      } else if (channel.languages.contains('Japan')) {
        channel.languages.remove("Japan");
        channel.languages.add(getLocalizedLanguage(JAPANESE, context));
      } else if (channel.languages.contains('CA')) {
        channel.languages.remove('CA');
        channel.languages.add(getLocalizedLanguage(ENGLISH, context));
      } else if (channel.languages.any((l) => l.startsWith('Mandarin'))) {
        channel.languages.removeWhere((l) => l.startsWith('Mandarin'));
        channel.languages.add(getLocalizedLanguage(CHINESE, context));
      } else if (channel.languages.contains('Min')) {
        channel.languages.remove('Min');
        channel.languages.add(getLocalizedLanguage(CHINESE, context));
      } else if (channel.languages.contains('Modern')) {
        channel.languages.remove('Modern');
        channel.languages.add(getLocalizedLanguage(GREEK, context));
      } else if (channel.languages.contains('News')) {
        channel.languages.remove('News');
        channel.languages.add(getLocalizedLanguage(ENGLISH, context));
      } else if (channel.languages.contains('Panjabi')) {
        channel.languages.remove('Panjabi');
        channel.languages.add(getLocalizedLanguage(PUNJABI, context));
      } else if (channel.languages.contains('Western')) {
        channel.languages.remove('Western');
        channel.languages.add(getLocalizedLanguage(DUTCH, context));
      } else if (channel.languages.any((l) => l.startsWith('Yue'))) {
        channel.languages.removeWhere((l) => l.startsWith('Yue'));
        channel.languages.add(getLocalizedLanguage(CHINESE, context));
      } else if (channel.languages.contains('Central')) {
        channel.languages.remove('Central');
      } else if (channel.languages.contains('Dhivehi')) {
        channel.languages.remove('Dhivehi');
        channel.languages.add(getLocalizedLanguage(MALDIVIAN, context));
      } else if (channel.languages.contains('Kirghiz')) {
        channel.languages.remove('Kirghiz');
        channel.languages.add(getLocalizedLanguage(KYRGYZ, context));
      } else if (channel.languages.contains('Letzeburgesch')) {
        channel.languages.remove('Letzeburgesch');
        channel.languages.add(getLocalizedLanguage(LUXEMBOURGISH, context));
      } else if (channel.languages.contains('Northern Kurdish') || channel.languages.contains('Central Kurdish')) {
        channel.languages.removeWhere((e) => e == 'Central Kurdish' || e == 'Northern Kurdish');
        channel.languages.add(getLocalizedLanguage(KURDISH, context));
      } else if (channel.languages.contains('Assyrian Neo-Aramaic')) {
        channel.languages.remove('Assyrian Neo-Aramaic');
        channel.languages.add(getLocalizedLanguage(ASSYRIAN, context));
      } else if (channel.languages.contains('Norwegian Bokmål')) {
        channel.languages.remove('Norwegian Bokmål');
        channel.languages.add(getLocalizedLanguage(NORWEGIAN, context));
      } else if (channel.languages.any((l) => l.startsWith('Oriya'))) {
        channel.languages.removeWhere((l) => l.startsWith('Oriya'));
        channel.languages.add(getLocalizedLanguage(ODIA, context));
      }
    } else if (item.startsWith('tvg-logo') && (str = item.split('=').last).isNotEmpty) {
      channel.logo = str;
    } else if (item.startsWith('group-title') && (str = item.split('=').last).isNotEmpty) {
      channel.categories
          .addAll(str.split(';').where((element) => element != UNDEFINED).map((e) => getLocalizedCategory(e, context)));
    }
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
                    widget.language = getLocalizedLanguage(ANY_LANGUAGE, context);
                    widget.category = getLocalizedCategory(ANY_CATEGORY, context);
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
