// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ztv/bloc/bloc_playlist.dart';
import 'package:ztv/model/playlist.dart';
import 'package:ztv/widget/widget_channel.dart';
import 'package:ztv/widget/widget_dynamic_bar.dart';
// import 'package:ztv/widget/widget_dynamic_bar.dart';

import '../bloc/bloc_search.dart';
import '../model/channel.dart';
import '../util/util.dart';

class PlaylistWidget extends StatelessWidget {
  static const _TAG = 'PlaylistWidget';
  final PlaylistBloc _playlistBlock;
  final bool _canSave;
  final bool _isTrial;
  final String? _link;

  const PlaylistWidget(this._playlistBlock, this._link, this._canSave, this._isTrial, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    log(_TAG, 'build');
    return LayoutBuilder(
        builder: (ctx, cnstr) => Scaffold(
            appBar: AppBar(actions: [
              const SizedBox(width: 48),
              Expanded(child: DynamicBar(SearchBloc(_canSave), _playlistBlock)),
              if (_canSave)
                IconButton(
                    icon: const Icon(Icons.save, color: Colors.white),
                    onPressed: () => showDialog(context: context, builder: (_) =>  SaveDialog(_link!)))
            ]),
            body: StreamBuilder<List<Channel>>(
                stream: _playlistBlock.stream,
                builder: (context, snap) {
                  final data = snap.data;
                  return data == null
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.count(
                          crossAxisCount: cnstr.maxWidth >= 809 ? 5 : 3,
                          children: data.map((ch) => ChannelWidget(ch, _isTrial, _playlistBlock)).toList(growable: false));
                })));
  }
}

//                               widget._info.filterCategory = cat;
//                             }), () {
//                       widget._info.filterLanguage = getLocalizedLanguage(ANY_LANGUAGE, AppLocalizations.of(context));
//                       widget._info.filterCategory = getLocalizedCategory(ANY_CATEGORY, AppLocalizations.of(context));
//                     })),
//           if (widget._hasSavePlayList)
//             IconButton(
//                 icon: const Icon(Icons.save, color: Colors.white),
//                 onPressed: () => showDialog(context: context, builder: (_) => SaveDialog(widget._playlistLink, widget._db)))
//         ]),
//         body: FutureBuilder(
//             future: (widget._query == null || widget._query?.isEmpty == true) &&
//                     widget._info.filterLanguage == getLocalizedLanguage(ANY_LANGUAGE, AppLocalizations.of(context)) &&
//                     widget._info.filterCategory == getLocalizedCategory(ANY_CATEGORY, AppLocalizations.of(context))
//                 ? getChannels(widget._info.linkOrList)
//                 : getFilteredChannels(getChannels(widget._info.linkOrList), widget._query ?? ''),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.done) {
//                 if (snapshot.data == null) linkBroken = true;
//                 final w = MediaQuery.of(context).size.width;
//                 log(_PlaylistWidgetState.TAG, 'w=>$w');
//                 return linkBroken
//                     ? Center(
//                         child: Text(AppLocalizations.of(context)?.broken_link ?? 'Link is broken!',
//                             style: const TextStyle(fontSize: 25)))
//                     : GridView.count(
//                         crossAxisCount: w >= 809 ? 5 : 3, children: snapshot.data as List<Widget>, controller: _scrollController);
//               } else
//                 return const Center(child: CircularProgressIndicator());
//             }));
//   }
//
//   Future<List<Channel>> getChannels(link) async {
//     log(_PlaylistWidgetState.TAG, 'get channels link=>$link');
//     if (link is List<Channel>) {
//       for (final ch in link) {
//         ch.filterLanguage = widget._info.filterLanguage;
//         ch.filterCategory = widget._info.filterCategory;
//         _setSC(ch);
//       }
//       return Future.value(link);
//     } else if (link.startsWith('/')) return Future.value(fileToPlaylist(link));
//     // final fResults = await loadChannels(link, lans);
//     var fResults;
//     if (fResults.first.statusCode == 404) {
//       linkBroken = true;
//       return Future.value(null);
//     }
//     List<Channel>? channelsWithLans;
//     if (fResults.length == 2)
//       channelsWithLans = await compute(
//           parseLans,
//           IsolateModel(
//               const [], utf8decoder.convert(fResults.last.bodyBytes), PlaylistInfo(''), false, AppLocalizations.of(context)));
//
//     final model = IsolateModel(channelsWithLans ?? const [], utf8decoder.convert(fResults.first.bodyBytes), widget._info,
//         widget._hasSavePlayList, AppLocalizations.of(context));
//     late PlaylistInfo info;
//     try {
//       info = await compute(parse, model);
//       final t4 = DateTime.now().millisecondsSinceEpoch;
//       widget._info = info;
//       setState(() =>
//           widget._info.hasFilter = (widget._info.dropDownCategories.length > 1 || widget._info.dropDownLanguages.length > 1));
//     } catch (e) {
//       log(TAG, 'e=>$e');
//     }
//     widget._onSetInfo(info);
//     return info.linkOrList;
//   }
//
//   void _setSC(Channel element) => element.sc = _scrollController;
//
//   Future<List<Channel>> fileToPlaylist(link) => File(link).readAsString().then((value) =>
//       parse(IsolateModel(const [], value, widget._info, widget._hasSavePlayList, AppLocalizations.of(context))).linkOrList
//         ..forEach((_setSC)));
//
//   Future<List<Channel>> getFilteredChannels(Future<List<Channel>> f, String q) {
//     log(_PlaylistWidgetState.TAG, 'get filtered channels');
//     return f.then((list) => list.where((element) {
//           element.query = widget._query ?? '';
//           return ((q.isEmpty) ? true : element.title.toLowerCase().contains(q.toLowerCase())) &&
//               (widget._info.filterLanguage != getLocalizedLanguage(ANY_LANGUAGE, AppLocalizations.of(context))
//                   ? element.languages.contains(widget._info.filterLanguage)
//                   : true) &&
//               (widget._info.filterCategory != getLocalizedCategory(ANY_CATEGORY, AppLocalizations.of(context))
//                   ? element.categories.contains(widget._info.filterCategory)
//                   : true);
//         }).toList());
//   }
//
//   void dialog(ctx, submit, clear) => showDialog(
//       context: ctx,
//       builder: (_) => ZtvDialog(submit, clear, widget._info.filterLanguage, widget._info.filterCategory,
//           widget._info.dropDownLanguages, widget._info.dropDownCategories));
//
//   _onSearch(String? q) {
//     setState(() {
//       widget._query = q;
//     });
//   }
// }

// PlaylistInfo parse(IsolateModel model) {
//   log(TAG, 'parse');
//   final lines = model.data.split("\n");
//   final channelsWithLans = model.chs;
//   final info = model.info;
//   final locs = model.localizations;
//   final list = <Channel>[];
//   for (var i = 0; i < lines.length; i++) {
//     final line = lines[i];
//     if (line.startsWith('#EXTINF')) {
//       final split = line.split(',');
//       var title = split.last.replaceAll('====', '');
//       String link = lines[++i];
//       final endsWith = link.trim().endsWith('.png');
//       if (endsWith || badLink(link)) continue;
//       String? category;
//       if (link.startsWith('#EXTGRP')) {
//         category = link.split(':')[1];
//         i++;
//       }
//       while (!(link = lines[i]).startsWith('http')) i++;
//       final channel = Channel(
//           title,
//           link,
//           (offset, query, language, category, logo, ch) => onTap(link, list, offset, query, language, category, title, logo,
//               info.dropDownLanguages, info.dropDownCategories, info.hasFilter, () => list.remove(ch)));
//       if (category != null) channel.categories.add(getLocalizedCategory(category, locs));
//       if (title.contains(RegExp('FRANCE|\\|FR\\|'))) {
//         channel.languages.add(getLocalizedLanguage(FRENCH, locs));
//       } else if (title.contains(RegExp('\\|AR\\|'))) {
//         channel.languages.add(getLocalizedLanguage(ARABIC, locs));
//       } else if (title.contains(RegExp('USA|5USA'))) {
//         channel.languages.add(getLocalizedLanguage(ENGLISH, locs));
//       } else if (title.contains('NL')) {
//         channel.languages.add(getLocalizedLanguage(DUTCH, locs));
//       } else if (link.contains(RegExp('latino|\\|SP\\|'))) {
//         channel.languages.add(getLocalizedLanguage(SPANISH, locs));
//       } else if (title.contains(':')) {
//         switch (title.split(':').first) {
//           case 'FR':
//             channel.languages.add(getLocalizedLanguage(FRENCH, locs));
//             break;
//           case 'TR':
//             channel.languages.add(getLocalizedLanguage(TURKISH, locs));
//             break;
//         }
//       }
//       if (title.contains(RegExp('SPORTS?'))) {
//         channel.categories.add(getLocalizedCategory(SPORTS, locs));
//       } else if (title.contains('News')) {
//         channel.categories.add(getLocalizedCategory(NEWS, locs));
//       } else if (title.contains(RegExp('XXX|Brazzers'))) {
//         channel.categories.add(XXX);
//       } else if (title.contains(RegExp('BABY|CARTOON|JEUNESSE'))) {
//         channel.categories.add(getLocalizedCategory(KIDS, locs));
//       } else if (title.contains(RegExp('MTV|Music'))) {
//         channel.categories.add(getLocalizedCategory(MUSIC, locs));
//       }
//       if (title.toLowerCase().contains('weather')) {
//         channel.categories.add(getLocalizedCategory(WEATHER, locs));
//       }
//       var data = split.first;
//       for (final ch in channelsWithLans)
//         if (ch.url == channel.url) {
//           channel.languages.addAll(ch.languages);
//           channelsWithLans.remove(ch);
//           break;
//         }
//
//       setChannelProperties(data, channel, false, locs);
//       for (final l in channel.languages) {
//         if (!info.dropDownLanguages.contains(l)) info.dropDownLanguages.add(l);
//       }
//       for (final c in channel.categories) {
//         if (!info.dropDownCategories.contains(c)) info.dropDownCategories.add(c);
//       }
//       list.add(channel);
//     }
//   }
//   info.dropDownCategories.sort();
//   info.dropDownCategories.insert(0, getLocalizedCategory(ANY_CATEGORY, locs));
//   info.dropDownLanguages.sort();
//   info.dropDownLanguages.insert(0, getLocalizedLanguage(ANY_LANGUAGE, locs));
//   info.filterCategory = getLocalizedCategory(info.filterCategory, locs);
//   info.filterLanguage = getLocalizedLanguage(info.filterLanguage, locs);


class SaveDialog extends StatelessWidget {
  static const TAG = 'SaveDialog';
  final String _link;

  const SaveDialog(this._link, {Key? key}) : super(key: key);

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
          // if (playlistLink == null)
          //   Text(AppLocalizations
          //       .of(context)
          //       ?.playlist_link_broken ?? "Playlist link is broken. Can't save it.",
          //       style: const TextStyle(color: Colors.red))
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              if (name.isEmpty) return;
              savePlaylist(Playlist(name, _link));
              Navigator.of(context).pop();
            },
            child: const Text('OK'))
      ],
    );
  }

  savePlaylist(Playlist playlist) =>
      getDB().then((db) => db.insert('playlist', playlist.toMap(), conflictAlgorithm: ConflictAlgorithm.replace));
}
