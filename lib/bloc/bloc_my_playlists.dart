// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:ztv/bloc/bloc_base.dart';
import 'package:ztv/model/playlist.dart';

import '../util/util.dart';

class MyPlaylistsBloc extends BaseBloc {
  static const _TAG = 'MyPlaylistsBloc';
  final _ctr = StreamController<String>();

  get sink => _ctr.sink;
  late final Stream<List<Playlist>> stream;

  MyPlaylistsBloc() {
    stream = _getStream();
  }

  Stream<List<Playlist>> _getStream() async* {
    final db = await getDB();
    final list = (await db.query(TABLE_PLAYLIST))
        .map((Map<String, dynamic> m) => Playlist(m[COLUMN_TITLE], m[COLUMN_LINK]))
        .toList();
    yield list;
    await for (final urlToDel in _ctr.stream) {
      await db.delete(TABLE_PLAYLIST, where: 'link=?', whereArgs: [urlToDel]);
      yield list..removeWhere((p) => p.link == urlToDel);
    }
    log(_TAG, 'stream end');
  }
}
