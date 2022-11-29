// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:video_player/video_player.dart';
import 'package:ztv/bloc/bloc_player.dart';
import 'package:ztv/util/util.dart';

import '../model/data_player.dart';

class PlayerWidget extends StatelessWidget {
  static const _TAG = 'PlayerWidget';
  final PlayerBloc _playerBloc;
  final String _title;

  const PlayerWidget(this._playerBloc, this._title,{Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerData>(
        initialData: const PlayerData(),
        stream: _playerBloc.stream,
        builder: (context, snap) {
          final data = snap.data!;
          log(_TAG, 'data=>$data');
          if (data.pop) WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context, true));
          return Scaffold(
              backgroundColor: data.fullscreen ? Colors.black : Colors.white,
              appBar: data.fullscreen
                  ? null
                  : AppBar(title: Text(_title), actions: [
                      if (!data.isTrial && data.state != PlayerState.AUDIO)
                        IconButton(
                            icon: const Icon(Icons.fullscreen),
                            onPressed: () => SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [])
                                .then((value) => SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]))
                                .then((_) => _playerBloc.sink.add(PlayerCmd.TOGGLE_SCREEN)))
                    ]),
              body: _getBody(data, context));
        });
  }

  void _onScreenTap() {
    log(_TAG, 'on screen tap');
    _playerBloc.sink.add(PlayerCmd.TOGGLE_CONTROLS);
  }

  _getBody(PlayerData data, BuildContext context) {
    final state = data.state;
    final ctr = data.vCtr;
    switch (state) {
      case PlayerState.OFF:
        return const _WidgetChOff();
      case PlayerState.LOADING:
        return const Center(child: CircularProgressIndicator());
      case PlayerState.VIDEO:
        return Stack(children: [
          Align(
              alignment: Alignment.topCenter,
              child: AspectRatio(
                  aspectRatio: data.aspectRatio,
                  child: Stack(fit: StackFit.expand, children: [
                    GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _onScreenTap,
                        child: ctr is VlcPlayerController
                            ? VlcPlayer(controller: ctr, aspectRatio: data.aspectRatio)
                            : VideoPlayer(ctr)),
                    if (data.showControls)
                      Align(
                          child: IconButton(
                              icon: Icon(ctr.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                                  color: Colors.white, size: 48),
                              onPressed: () {
                                log(_TAG, 'on pressed');
                                _playerBloc.sink.add(PlayerCmd.PLAY_PAUSE);
                              }))
                  ]))),
          if (ctr is VlcPlayerController && ctr.value.playingState != PlayingState.playing)
            const Center(child: CircularProgressIndicator()),
          if (data.fullscreen)
            Positioned(
                bottom: 4,
                right: 4,
                child: IconButton(
                    icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                    onPressed: () => SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                            overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom])
                        .then((value) => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]))
                        .then((value) => _playerBloc.sink.add(PlayerCmd.TOGGLE_SCREEN))))
        ]);
      case PlayerState.AUDIO:
        return Column(children: [
          Center(
              child: Text(
            AppLocalizations.of(context)?.audio ?? 'This is an audio file!',
            style: const TextStyle(fontSize: 24),
          )),
          Padding(
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                IconButton(
                    icon: Icon((ctr as VideoPlayerController).value.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () => _playerBloc.sink.add(PlayerCmd.PLAY_PAUSE)),
                Expanded(
                    child: StreamBuilder<double>(
                        initialData: 0,
                        stream: _playerBloc.progressStream,
                        builder: (context, snap) => Slider(
                            value: snap.data!,
                            activeColor: Colors.black,
                            onChangeEnd: (v) =>
                                ctr.seekTo(Duration(milliseconds: (v * ctr.value.duration.inMilliseconds).toInt())),
                            onChanged: _playerBloc.progressSink.add)))
              ]))
        ]);
      default:
        throw 'not implemented';
    }
  }
}

class _WidgetChOff extends StatelessWidget {
  const _WidgetChOff({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(AppLocalizations.of(context)?.ch_offline ?? 'This channel is offline now. Come later please',
            textScaleFactor: 1.25));
  }
}
