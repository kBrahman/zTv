// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:ztv/bloc/bloc_base.dart';

class UIStateBloc extends BaseBloc {
  final _controller = StreamController<UIState>();

  Sink<UIState> get state => _controller.sink;

  Stream<UIState> get stream => _controller.stream;
}

enum UIState { MAIN, PLAYLIST, MY_PLAYLISTS, MY_IPTV, HISTORY, TRY_IPTV }
