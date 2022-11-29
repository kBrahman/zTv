// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ztv/bloc/bloc_my_playlists.dart';
import 'package:ztv/bloc/bloc_playlist.dart';
import 'package:ztv/model/playlist.dart';
import 'package:ztv/util/util.dart';
import 'package:ztv/widget/widget_playlist.dart';

class MyPlaylists extends StatelessWidget {
  static const _TAG = 'MyPlaylists';
  final MyPlaylistsBloc _bloc;

  const MyPlaylists(this._bloc, {Key? key}) : super(key: key);

  Future<List<Playlist>> myPlaylists() async {
    final List<Map<String, dynamic>> maps = await (await getDB()).query(TABLE_PLAYLIST);
    return List.generate(maps.length, (i) => Playlist(maps[i][COLUMN_TITLE], maps[i][COLUMN_LINK]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)?.my_playlists ?? 'My playlists')),
        body: StreamBuilder<List<Playlist>>(
            stream: _bloc.stream,
            builder: (ctx, snap) {
              final list = snap.data;
              log(_TAG, 'list=>$list');
              if (list == null) return const Center(child: CircularProgressIndicator());
              return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                      children: List.generate(
                          (list).length,
                          (i) => GestureDetector(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (c) => PlaylistWidget(PlaylistBloc(list[i].link), list[i].link, false, false))),
                              // behavior: HitTestBehavior.opaque,
                              child: Row(children: [
                                Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(list[i].name, style: const TextStyle(fontSize: 20))),
                                const Spacer(),
                                IconButton(icon: const Icon(Icons.delete), onPressed: () => _bloc.sink.add(list[i].link))
                              ])))));
            }));
  }

  Future delete(String link) async {
    final Database db = await openDatabase(
      join(await getDatabasesPath(), DB_NAME),
      version: 1,
    );
    await db.delete(TABLE_PLAYLIST, where: 'link=?', whereArgs: [link]);
  }
}
