// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart';
import 'package:sqflite/sqflite.dart';
import 'package:video_player/video_player.dart';

import '../model/data_player.dart';
import '../util/util.dart';
import 'bloc_base.dart';

class PlayerBloc extends BaseBloc {
  static const _TAG = 'PlayerBloc';
  static const defaultRatio = 1.28;
  VideoPlayerController? _vCtr;
  VlcPlayerController? _vlcCtr;
  final _ctr = StreamController<PlayerCmd?>();
  late final Stream<PlayerData> stream;
  _ControlVisibilityTimeout? _ctrVisibilityTimeout;
  late final bool _isAudio;
  final progressCtr = StreamController<double>();

  get progressStream => progressCtr.stream;

  get progressSink => progressCtr.sink;

  get sink => _ctr.sink;

  PlayerBloc(String url, bool isTrial, title, logo) {
    if (url.startsWith('https://59c5c86e10038.streamlock.net')) {
      url = url.replaceFirst('59c5c86e10038.streamlock.net', 'panel.dattalive.com');
    }
    log(_TAG, 'url=>$url');
    _isAudio = _isAudioLink(url);
    stream = _getStream(url: url, title: title, logo: logo, isTrial: isTrial);
  }

  bool _isAudioLink(String link) =>
      link.endsWith('.mp3') || link.endsWith('.opus') || link.endsWith('.flac') || link.endsWith('.ogg');

  Stream<PlayerData> _getStream({required String url, title = '', String? logo, delegate = false, required bool isTrial}) async* {
    PlayerData data;
    if (url.startsWith('rtmp://') || delegate) {
      log(_TAG, 'trying with VLC');
      _vlcCtr = VlcPlayerController.network(url, autoPlay: true);
      yield data = PlayerData(state: PlayerState.VIDEO, vCtr: _vlcCtr, aspectRatio: defaultRatio, isTrial: isTrial);
      await for (final t in Stream.periodic(const Duration(seconds: 1), (i) => i)) {
        log(_TAG, 'ctr=>$_vlcCtr');
        if (_vlcCtr?.value.playingState == PlayingState.stopped || t == 13) {
          (await BaseBloc.myIptvIsoRes!).channels.removeWhere((ch) => ch.url == url);
          yield data = data.copyWith(state: PlayerState.OFF);
          return;
        } else if (_vlcCtr?.value.playingState == PlayingState.playing) {
          final aspectRatio = _vlcCtr?.value.aspectRatio == 0 ? defaultRatio : _vlcCtr?.value.aspectRatio;
          // await Future.delayed(const Duration(seconds: 5));
          log(_TAG, '5 end');
          yield data = data.copyWith(aspectRatio: aspectRatio);
          break;
        }
      }
    } else {
      _vCtr = VideoPlayerController.network(url);
      try {
        await _vCtr?.initialize();
      } on PlatformException catch (e) {
        log(_TAG, 'e=>$e');
        if (e.message?.contains('Source error') == true) {
          yield* _getLocation(vCtr: _vCtr!, url: url, title: title, logo: logo, isTrial: isTrial);
          return;
        }
      }
      final aspectRatio = _vCtr!.value.size.aspectRatio == 0 ? defaultRatio : _vCtr!.value.size.aspectRatio;
      yield data = PlayerData(
          state: _isAudio ? PlayerState.AUDIO : PlayerState.VIDEO, vCtr: _vCtr, aspectRatio: aspectRatio, isTrial: isTrial);
      _vCtr?.play();
      if (_isAudio) sink.add(PlayerCmd.TRACK_PROGRESS);
    }
    if (isTrial)
      Future.delayed(const Duration(seconds: 3), () => sink.add(PlayerCmd.TRIAL_END));
    else
      _saveToDB(url, title, logo);
    await for (final cmd in _ctr.stream) {
      log(_TAG, 'cmd=>$cmd');
      switch (cmd) {
        case PlayerCmd.TRIAL_END:
          yield data = data.copyWith(pop: true);
          break;
        case PlayerCmd.TOGGLE_SCREEN:
          yield data = data.copyWith(fullscreen: !data.fullscreen);
          break;
        case PlayerCmd.TOGGLE_CONTROLS:
          data = data.copyWith(showControls: !data.showControls);
          _ctrVisibilityTimeout?.cancelled = true;
          if (data.showControls) _ctrVisibilityTimeout = _ControlVisibilityTimeout(sink);
          yield data;
          break;
        case PlayerCmd.PLAY_PAUSE:
          data.vCtr.value.isPlaying ? data.vCtr.pause() : data.vCtr.play();
          yield data;
          break;
        case PlayerCmd.TRACK_PROGRESS:
          Future.delayed(const Duration(milliseconds: 1600), () {
            progressSink.add(_vCtr!.value.position.inMilliseconds / _vCtr!.value.duration.inMilliseconds);
            sink.add(PlayerCmd.TRACK_PROGRESS);
          });
          yield data;
          break;
        default:
          yield data;
      }
    }
  }

  void dispose() {
    _vCtr?.dispose();
    _vlcCtr?.stopRendererScanning();
    _vlcCtr?.dispose();
  }

  Stream<PlayerData> _getLocation(
      {required VideoPlayerController vCtr, required String url, title = '', String? logo, isTrial = false}) async* {
    Request req = Request("Get", Uri.parse((vCtr).dataSource))..followRedirects = false;
    Client baseClient = Client();
    late final BaseResponse resp;
    try {
      resp = await baseClient.send(req);
    } on HandshakeException {
      await securityOff();
      yield* _getStream(url: url, title: title, logo: logo, delegate: false, isTrial: isTrial);
      return;
    } catch (e) {
      log(_TAG, 'generic err=>${e.runtimeType}');
      (await BaseBloc.myIptvIsoRes!).channels.removeWhere((ch) => ch.url == url);
      yield const PlayerData(state: PlayerState.OFF);
      return;
    }
    final statusCode = resp.statusCode;
    log(_TAG, 'code=>$statusCode');
    if (statusCode == 403 || statusCode == 404 || statusCode == 401 || statusCode == 504 || statusCode == 400) {
      (await BaseBloc.myIptvIsoRes!).channels.removeWhere((ch) => ch.url == url);
      yield const PlayerData(state: PlayerState.OFF);
    } else {
      final loc = resp.headers['location'];
      log(_TAG, 'loc=>$loc');
      yield* _getStream(url: loc ?? url, title: title, logo: logo, delegate: loc == null, isTrial: isTrial);
    }
  }

  _saveToDB(String url, title, logo) => getDB().then(
      (db) => db.insert('history', {'title': title, 'link': url, 'logo': logo}, conflictAlgorithm: ConflictAlgorithm.abort));
}

class _ControlVisibilityTimeout {
  static const _TAG = '_ControlVisibilityTimeout';
  var cancelled = false;

  _ControlVisibilityTimeout(sink) {
    Future.delayed(const Duration(seconds: 2), () {
      if (!cancelled) sink.add(PlayerCmd.TOGGLE_CONTROLS);
    });
  }
}

enum PlayerState { LOADING, VIDEO, AUDIO, OFF }

enum PlayerCmd { TOGGLE_SCREEN, TOGGLE_CONTROLS, PLAY_PAUSE, TRIAL_END, TRACK_PROGRESS }
