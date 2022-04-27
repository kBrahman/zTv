import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ztv/model/playlist.dart';
import 'package:ztv/util/util.dart';

class MyPlaylists extends StatefulWidget {
  final Function(String link) onPlaylistTap;
  final Database db;

  const MyPlaylists(this.onPlaylistTap, this.db, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MyPlaylistsState();
}

class MyPlaylistsState extends State<MyPlaylists> {
  late Future<List<Playlist>> future;

  @override
  void initState() {
    future = myPlaylists();
    super.initState();
  }

  Future<List<Playlist>> myPlaylists() async {
    final List<Map<String, dynamic>> maps = await widget.db.query(TABLE_PLAYLIST);
    return List.generate(maps.length, (i) => Playlist(maps[i]['name'], maps[i]['link']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: Text(AppLocalizations.of(context)?.my_playlists ?? 'My playlists')),
        body: FutureBuilder(
            future: future,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.done) {
                var list = snap.data as List<Playlist>;
                return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                        children: List.generate(
                            (list).length,
                            (i) => GestureDetector(
                                onTap: () => widget.onPlaylistTap(list[i].link),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Text(list[i].name, style: const TextStyle(fontSize: 20))),
                                    const Spacer(),
                                    IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          setState(() {
                                            future = delete(list[i].link).then((_) => myPlaylists());
                                          });
                                        })
                                  ],
                                )))));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
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
