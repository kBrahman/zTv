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

class PlaylistWidget extends StatefulWidget {
  var _linkOrList;

  final onTap;

  final _offset;

  String _query;
  var _language;
  var _category;
  final _txtFieldTxt;
  final _availableLanguages;
  final List<String> _availableCategories;
  var hasFilter;

  PlaylistWidget(this._linkOrList, this.onTap, this._offset, this._query, this._language, this._category,
      this._txtFieldTxt, this._availableLanguages, this._availableCategories, this.hasFilter);

  @override
  State<StatefulWidget> createState() => _PlaylistWidgetState();
}

class _PlaylistWidgetState extends State<PlaylistWidget> {
  static const TAG = '_PlaylistState';

  Future<List<Widget>> future;
  ScrollController _scrollController;
  var showSearchView = false;
  var ctr;
  bool linkBroken = false;

  @override
  void initState() {
    _scrollController = ScrollController(initialScrollOffset: widget._offset);
    future = getChannels(widget._linkOrList);
    ctr = TextEditingController(text: widget._query);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var searchActive = showSearchView || (widget._query != null && widget._query.isNotEmpty);
    return Scaffold(
      appBar: AppBar(
        actions: [
          const SizedBox(width: 12),
          const Align(
              child: const Text(
            'zTv',
            style: TextStyle(fontSize: 20),
          )),
          const SizedBox(width: 16),
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
                          })))
              : SizedBox.shrink(),
          IconButton(
              icon: Icon(Icons.save, color: Colors.white),
              onPressed: () => showDialog(context: context, builder: (_) => SaveDialog(widget._txtFieldTxt)))
        ],
      ),
      body: FutureBuilder(
        future: (widget._query == null || widget._query.isEmpty) &&
                widget._language == ANY_LANGUAGE &&
                widget._category == ANY_CATEGORY
            ? future
            : getFilteredChannels(getChannels(widget._linkOrList), widget._query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return linkBroken
                ? Center(child: Text('Link is broken!', style: TextStyle(fontSize: 25)))
                : GridView.count(
                    crossAxisCount: 3,
                    children: snapshot.data,
                    controller: _scrollController,
                  );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<List<Channel>> getChannels(link) {
    if (link is List<Channel>) {
      link.forEach((ch) {
        if (ch.isOff) {
          link.remove(ch);
        } else {
          ch.sc = _scrollController;
        }
      });
      return Future.value(link);
    } else if (link.startsWith('/')) {
      return Future.value(fileToPlaylist(link));
    }
    return http.get(widget._linkOrList).then((value) {
      if (value.statusCode == 404) {
        linkBroken = true;
        return Future.value(null);
      }
      final data = Utf8Decoder().convert(value.bodyBytes);
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
        var link = lines[i + 1];
        final channel = Channel(
            title,
            link,
            (String url, offset, query, language, category) => widget.onTap(url, list, offset, query, language,
                category, title, widget._availableLanguages, widget._availableCategories, widget.hasFilter));
        channel.sc = _scrollController;
        if (title.contains(RegExp('FRANCE|\\|FR\\|'))) {
          channel.languages.add(FRENCH);
        } else if (title.contains(RegExp('\\|AR\\|'))) {
          channel.languages.add(ARABIC);
        } else if (title.contains(RegExp('USA|5USA|eng'))) {
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
          channel.category = SPORT;
        } else if (title.contains('News')) {
          channel.category = NEWS;
        } else if (title.contains(RegExp('XXX|Adult|Brazzers'))) {
          channel.category = ADULT;
        } else if (title.contains(RegExp('BABY|CARTOON|JEUNESSE'))) {
          channel.category = KIDS;
        } else if (title.contains('MTV')) {
          channel.category = MUSIC;
        }
        if (link.contains(RegExp('movie|CINE'))) {
          channel.category = MOVIE;
        }
        var data = split.first;
        setChProps(data.split(' '), channel);
        for (final l in channel.languages) {
          if (!widget._availableLanguages.contains(l)) widget._availableLanguages.add(l);
        }
        if (!widget._availableCategories.contains(channel.category)) widget._availableCategories.add(channel.category);
        list.add(channel);
      }
    }
    setState(
        () => widget.hasFilter = (widget._availableCategories.length > 1 || widget._availableCategories.length > 1));
    widget._linkOrList = list;
    return Future.value(list);
  }

  Future<List<Channel>> getFilteredChannels(Future<List<Channel>> f, String q) {
    return f.then((list) {
      var filteredList = list.where((element) {
        element.query = widget._query;
        element.lan = widget._language;
        element.cat = widget._category;
        return ((q == null || q.isEmpty) ? true : element.title.toLowerCase().contains(q.toLowerCase())) &&
            (widget._language != ANY_LANGUAGE ? element.languages.contains(widget._language) : true) &&
            (widget._category != ANY_CATEGORY ? element.category == widget._category : true);
      }).toList();
      return filteredList;
    });
  }

  void dialog(ctx, submit) => showDialog(
      context: ctx,
      builder: (_) {
        return ZtvDialog(
            submit, widget._language, widget._category, widget._availableLanguages, widget._availableCategories);
      });

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
      title: Text('Save playlist'),
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
  var language;
  var category;
  final List<String> availableLanguages;
  final availableCategories;

  ZtvDialog(this.submit, this.language, this.category, this.availableLanguages, this.availableCategories);

  @override
  State<StatefulWidget> createState() => DialogState();
}

class DialogState extends State<ZtvDialog> {
  static const TAG = 'DialogState';

  @override
  Widget build(BuildContext context) {
    var lanItem = SpinnerAndTitle(widget.language, 'Language', widget.availableLanguages);
    var catItem = SpinnerAndTitle(widget.category, 'Category', widget.availableCategories);
    return AlertDialog(
        title: Text('Filter'),
        actions: [
          TextButton(onPressed: () => widget.submit(ANY_LANGUAGE, ANY_CATEGORY), child: Text('Clear')),
          TextButton(
              onPressed: () {
                widget.submit(lanItem.dropdownValue, catItem.dropdownValue);
                Navigator.of(context).pop();
              },
              child: Text('OK'))
        ],
        content: Row(
          children: [lanItem, SizedBox(width: 8), catItem],
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
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title),
        DropdownButton<String>(
          value: widget.dropdownValue,
          onChanged: (String newValue) {
            setState(() {
              widget.dropdownValue = newValue;
            });
            // widget.onChanged(newValue);
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
