// ignore_for_file: curly_braces_in_flow_control_structures, constant_identifier_names

import 'dart:async';

import 'package:ztv/bloc/bloc_base.dart';

import '../model/channel.dart';
import '../model/isolate_res.dart';
import '../util/util.dart';

class PlaylistBloc extends BaseBloc {
  static const _TAG = 'PlaylistBloc';
  final _controller = StreamController<FilterEvent?>();

  Sink<FilterEvent?> get sink => _controller.sink;
  late Stream<List<Channel>> stream;

  PlaylistBloc(link) {
    if (link != null) BaseBloc.isoRes = BaseBloc.loadChannels(link, null).catchError((e) => const IsolateRes([], {}, {}));
    stream = _getStream(link == null);
  }

  Stream<List<Channel>> _getStream(isMyIptv) async* {
    final list = (await (isMyIptv ? BaseBloc.myIptvIsoRes : BaseBloc.isoRes))!.channels;
    yield list;
    var event = FilterEvent(ANY_LANGUAGE, ANY_CATEGORY, '');
    yield* _controller.stream.map((e) {
      if (e != null) event = e;
      return list
          .where((ch) =>
              ch.title.toLowerCase().contains(event.q.toLowerCase()) &&
              (event.lan == ANY_LANGUAGE || ch.languages.contains(event.lan)) &&
              ((event.cat == ANY_CATEGORY || ch.categories.contains(event.cat))))
          .toList(growable: false);
    });
  }
}

class FilterEvent {
  final String lan;
  final String cat;
  final String q;

  FilterEvent(this.lan, this.cat, this.q);
}
