import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ztv/model/playlist.dart';
import 'package:ztv/util/util.dart';
import 'package:ztv/widget/channel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlaylistWidget extends StatefulWidget {
  var _linkOrList;

  final onTap;

  final _offset;

  String? _query;
  var _language;
  var _category;
  final _txtFieldTxt;
  final List<String> _dropDownLanguages;
  final List<String> _dropDownCategories;
  var hasFilter;
  var hasSavePlayList;
  final _xLink;

  PlaylistWidget(this._linkOrList, this._xLink, this.onTap, this._offset, this._query, this._language, this._category,
      this._txtFieldTxt, this._dropDownLanguages, this._dropDownCategories, this.hasFilter, this.hasSavePlayList);

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
      appBar: AppBar(
        leading: BackButton(),
        actions: [
          const SizedBox(width: 48),
          Expanded(
              child: searchActive
                  ? TextField(
                      style: TextStyle(color: Colors.white),
                      onChanged: (String txt) {
                        if (txt.trim().isNotEmpty)
                          setState(() {
                            widget._query = txt;
                          });
                      },
                      controller: ctr,
                      cursorColor: Colors.white,
                      // controller: TextEditingController(text: widget._query),
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(top: 16),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
                    )
                  : Container()),
          searchActive
              ? IconButton(
                  icon: Icon(
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
                  icon: Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => showSearchView = true)),
          widget.hasFilter
              ? IconButton(
                  icon: Icon(Icons.filter_list, color: Colors.white),
                  onPressed: () => dialog(
                          context,
                          (lan, cat) => setState(() {
                                widget._language = lan;
                                widget._category = cat;
                                log(TAG, "submit lan=>$lan; cat=>$cat");
                              }), () {
                        widget._language = ANY_LANGUAGE;
                        widget._category = ANY_CATEGORY;
                      }))
              : SizedBox.shrink(),
          if (widget.hasSavePlayList)
            IconButton(
                icon: Icon(Icons.save, color: Colors.white),
                onPressed: () => showDialog(context: context, builder: (_) => SaveDialog(widget._txtFieldTxt)))
        ],
      ),
      body: FutureBuilder(
        future: (widget._query == null || widget._query?.isEmpty == true) &&
                widget._language == ANY_LANGUAGE &&
                widget._category == ANY_CATEGORY
            ? getChannels(widget._linkOrList, widget._xLink)
            : getFilteredChannels(getChannels(widget._linkOrList, widget._xLink), widget._query ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return linkBroken
                ? Center(
                    child: Text(AppLocalizations.of(context)?.broken_link ?? 'Link is broken!',
                        style: TextStyle(fontSize: 25)))
                : GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width >= 834 ? 4 : 3,
                    children: snapshot.data as List<Widget>,
                    controller: _scrollController,
                  );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<List<Channel>> getChannels(link, xLink) {
    log(TAG, 'getChannels');
    if (link is List<Channel>) {
      link.forEach((ch) {
        if (ch.isOff) {
          link.remove(ch);
        } else {
          ch.filterLanguage = widget._language;
          ch.filterCategory = widget._category;
          ch.sc = _scrollController;
        }
      });
      return Future.value(link);
    } else if (link.startsWith('/')) {
      return Future.value(fileToPlaylist(link));
    }
    return http.get(Uri.parse(widget._linkOrList)).then((value) async {
      if (value.statusCode == 404) {
        linkBroken = true;
        return Future.value(null);
      }
      var data = Utf8Decoder().convert(value.bodyBytes);
      if (xLink != null) {
        final xData = await http.get(Uri.parse(xLink));
        data += Utf8Decoder().convert(xData.bodyBytes);
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
        var category;
        if (link.startsWith('#EXTGRP')) {
          category = link.split(':')[1];
          i++;
        }
        while (!(link = lines[i]).startsWith('http')) i++;
        final channel = Channel(
            title,
            link,
            (String url, offset, query, language, category) => widget.onTap(url, list, offset, query, language, category,
                title, widget._dropDownLanguages, widget._dropDownCategories, widget.hasFilter));
        channel.sc = _scrollController;
        if (category != null) channel.category = category;
        if (title.contains(RegExp('FRANCE|\\|FR\\|'))) {
          channel.languages.add(FRENCH);
        } else if (title.contains(RegExp('\\|AR\\|'))) {
          channel.languages.add(ARABIC);
        } else if (title.contains(RegExp('USA|5USA'))) {
          channel.languages.add(ENGLISH);
        } else if (title.contains('NL')) {
          channel.languages.add(DUTCH);
        } else if (link.contains(RegExp('latino|\\|SP\\|'))) {
          channel.languages.add(SPANISH);
        } else if (title.contains(':')) {
          switch (title.split(':').first) {
            case 'FR':
              channel.languages.add(FRENCH);
              break;
            case 'TR':
              channel.languages.add(TURKISH);
              break;
          }
        }
        if (title.contains(RegExp('SPORTS?'))) {
          channel.category = SPORTS;
        } else if (title.contains('News')) {
          channel.category = NEWS;
        } else if (title.contains(RegExp('XXX|Brazzers'))) {
          channel.category = XXX;
        } else if (title.contains(RegExp('BABY|CARTOON|JEUNESSE'))) {
          channel.category = KIDS;
        } else if (title.contains('MTV')) {
          channel.category = MUSIC;
        }
        if (title.toLowerCase().contains('weather')) {
          channel.category = WEATHER;
        }
        var data = split.first;
        setChProps(data.split(' '), channel);
        for (final l in channel.languages) {
          if (!widget._dropDownLanguages.contains(l)) widget._dropDownLanguages.add(l);
        }
        if (!widget._dropDownCategories.contains(channel.category)) widget._dropDownCategories.add(channel.category);
        list.add(channel);
      }
    }
    widget._dropDownCategories.sort((e1, e2) => e1 == ANY_CATEGORY
        ? -1
        : e2 == ANY_CATEGORY
            ? 1
            : e1.compareTo(e2));
    widget._dropDownLanguages.sort((e1, e2) => e1 == ANY_LANGUAGE
        ? -1
        : e2 == ANY_LANGUAGE
            ? 1
            : e1.compareTo(e2));
    setState(() => widget.hasFilter = (widget._dropDownCategories.length > 1 || widget._dropDownLanguages.length > 1));
    widget._linkOrList = list;
    return Future.value(list);
  }

  Future<List<Channel>> getFilteredChannels(Future<List<Channel>> f, String q) => f.then((list) => list.where((element) {
        element.query = widget._query ?? '';
        return ((q.isEmpty) ? true : element.title.toLowerCase().contains(q.toLowerCase())) &&
            (widget._language != ANY_LANGUAGE ? element.languages.contains(widget._language) : true) &&
            (widget._category != ANY_CATEGORY ? element.category == widget._category : true);
      }).toList());

  void dialog(ctx, submit, clear) => showDialog(
      context: ctx,
      builder: (_) => ZtvDialog(
          submit, clear, widget._language, widget._category, widget._dropDownLanguages, widget._dropDownCategories));

  setChProps(List<String> data, Channel channel) {
    for (final item in data) {
      String str;
      if (item.startsWith('tvg-language') && (str = item.split('=').last.replaceAll('"', '')).isNotEmpty) {
        channel.languages.addAll(str.split(';'));
      } else if (item.startsWith('tvg-logo') && (str = item.split('=').last.replaceAll('"', '')).isNotEmpty) {
        channel.logo = str;
      } else if (item.startsWith('group-title') && (str = item.split('=').last.replaceAll('"', '')).isNotEmpty) {
        channel.category = str;
      }
    }
  }
}

class SaveDialog extends StatelessWidget {
  static const TAG = 'SaveDialog';

  var link;

  SaveDialog(this.link);

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
          )
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              if (name.isEmpty) return;
              savePlaylist(Playlist(name, link));
              Navigator.of(context).pop();
            },
            child: Text('Save'))
      ],
    );
  }

  Future<void> savePlaylist(Playlist playlist) async {
    openDatabase(join(await getDatabasesPath(), DB_NAME), onCreate: (db, v) {
      return db.execute('CREATE TABLE playlist(name TEXT, link TEXT PRIMARY KEY)');
    }, version: 1)
        .then((db) => db.insert('playlist', playlist.toMap(), conflictAlgorithm: ConflictAlgorithm.replace));
  }
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
    var languageSpinnerAndTitle =
        SpinnerAndTitle(widget.language, AppLocalizations.of(context)?.language ?? 'Language', widget.dropDownLanguages);
    var categorySpinnerAndTitle =
        SpinnerAndTitle(widget.category, AppLocalizations.of(context)?.category ?? 'Category', widget.dropDownCategories);
    return AlertDialog(
        title: Padding(child: Text(AppLocalizations.of(context)?.filter ??'Filter'), padding: EdgeInsets.only(bottom: 16)),
        contentPadding: const EdgeInsets.only(left: 4, right: 4),
        actions: [
          TextButton(
              onPressed: () => setState(() {
                    widget.language = ANY_LANGUAGE;
                    widget.category = ANY_CATEGORY;
                    widget.clear();
                  }),
              child: Text('Clear')),
          TextButton(
              onPressed: () {
                widget.submit(languageSpinnerAndTitle.dropdownValue, categorySpinnerAndTitle.dropdownValue);
                Navigator.of(context).pop();
              },
              child: Text('OK'))
        ],
        content: Row(
          children: [
            Padding(padding: EdgeInsets.only(right: 2), child: languageSpinnerAndTitle),
            Padding(padding: EdgeInsets.only(left: 2), child: categorySpinnerAndTitle)
          ],
        ));
  }
}

class SpinnerAndTitle extends StatefulWidget {
  var dropdownValue;
  String title;
  final items;

  SpinnerAndTitle(this.dropdownValue, this.title, this.items);

  @override
  State<StatefulWidget> createState() => SpinnerAndTitleState();
}

class SpinnerAndTitleState extends State<SpinnerAndTitle> {
  static const TAG = 'SpinnerAndTitleState';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title),
        DropdownButton<String>(
          value: widget.dropdownValue,
          onChanged: (String? newValue) {
            log(TAG, "on changed new val=>$newValue");
            setState(() {
              widget.dropdownValue = newValue;
            });
          },
          items: widget.items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        )
      ],
    );
  }
}
