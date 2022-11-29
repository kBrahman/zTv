// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import '../model/channel.dart';
import '../util/util.dart';

class Player extends StatefulWidget {
  final String _link;
  final String _title;
  final String? _logo;
  final bool isTrial;

  const Player(this._link, this._title, this._logo, this.isTrial, {Key? key}) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  static const TAG = '_PlayerState';
  late dynamic _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool fullscreen = false;
  bool _delegateToVLC = false;
  bool isPlaying = false;
  var controlVisible = false;
  bool paused = false;
  var chOff = false;
  bool inserted = false;
  bool _securityOff = false;

  @override
  void initState() {
    var dataSource = widget._link;
    if (dataSource.startsWith('https://59c5c86e10038.streamlock.net')) {
      dataSource = dataSource.replaceFirst('59c5c86e10038.streamlock.net', 'panel.dattalive.com');
    }
    _delegateToVLC = delegate(dataSource);
    initVideo(dataSource);
    super.initState();
  }

  void initVideo(String dataSource) {
    log(_PlayerState.TAG, 'initVideo, ds=>$dataSource');
    if (_delegateToVLC)
      initVLC(dataSource);
    else {
      _controller = VideoPlayerController.network(dataSource);
      setState(() {
        _initializeVideoPlayerFuture = (_controller as VideoPlayerController).initialize();
      });
    }
  }

  void initVLC(String url) {
    log(TAG, 'init vlc');
    try {
      _controller = VlcPlayerController.network(url, autoPlay: true)
        ..addOnInitListener(() {
          log(TAG, 'on init callback, is playing=>${_controller.value}');
          repeatedCheck(_controller);
        });
    } catch (e) {
      log(_PlayerState.TAG, 'vlc e=>$e');
    }
  }

  getUrl(dataSource) => dataSource is Channel ? dataSource.url : dataSource;

  @override
  void dispose() {
    _controller.dispose();
    // platform.invokeMethod('securityOn');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAudioFile = (widget._link.endsWith('.mp3') || widget._link.endsWith('.flac'));
    final miniMaxWidget = Positioned(
      bottom: 4,
      right: 4,
      child: IconButton(
          icon: const Icon(
            Icons.fullscreen_exit,
            color: Colors.white,
          ),
          onPressed: () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
              .then((value) => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]))
              .then((value) => setState(() => fullscreen = false))),
    );

    return Scaffold(
        backgroundColor: fullscreen ? Colors.black : Colors.white,
        appBar: fullscreen
            ? null
            : AppBar(leading: const BackButton(), title: Text(isAudioFile ? getName(widget._link) : widget._title), actions: [
                if (!isAudioFile)
                  IconButton(
                      icon: const Icon(Icons.fullscreen),
                      onPressed: () => SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top])
                          .then((value) => SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]))
                          .then((value) => setState(() => fullscreen = true)))
              ]),
        body: chOff
            ? const WidgetChOff()
            : _delegateToVLC
                ? Stack(children: [
                    Align(
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                            onTap: _onScreenTap,
                            child: Stack(children: [
                              VlcPlayer(
                                controller: _controller,
                                aspectRatio: (_controller.value.size != null && _controller.value.size.aspectRatio != 0.0)
                                    ? _controller.value.size.aspectRatio
                                    : fullscreen
                                        ? .6
                                        : 1.7,
                              ),
                              if (controlVisible)
                                Align(
                                    child: IconButton(
                                        icon: Icon(_controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                                            color: Colors.white, size: 48),
                                        onPressed: () {
                                          if (_controller.value.isPlaying) _controller.pause();
                                          setState(() {
                                            paused = !paused;
                                          });
                                        }))
                            ]))),
                    if (fullscreen) miniMaxWidget,
                    if (!isPlaying) pb()
                  ])
                : FutureBuilder(
                    future: _initializeVideoPlayerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        final err = snapshot.error;
                        var hasError = snapshot.hasError;
                        if (hasError && err is PlatformException && err.message?.contains('Source error') == true) {
                          log((_PlayerState.TAG), 'platform exc=>$err');
                          http.Request req = http.Request("Get", Uri.parse((_controller as VideoPlayerController).dataSource))
                            ..followRedirects = false;
                          http.Client baseClient = http.Client();
                          baseClient.send(req).then((resp) {
                            final loc = resp.headers['location'];
                            log(TAG, 'loc=>$loc');
                            var statusCode = resp.statusCode;
                            log(_PlayerState.TAG, 'code=>$statusCode');
                            log(_PlayerState.TAG, 'resp=>$resp');
                            if (loc != null)
                              setState(() {
                                _controller = VideoPlayerController.network(loc);
                                _initializeVideoPlayerFuture = _controller.initialize();
                              });
                            else if (statusCode == 403 || statusCode == 404 || statusCode == 401 || statusCode == 504)
                              _off();
                            else
                              initAndSetDelegate(widget._link);
                          }, onError: (e, s) {
                            log(TAG, 'on err, e=>$e, s=>$s');
                            if (e is SocketException)
                              _off();
                            else if (e is HandshakeException && !_securityOff) {
                              // platform.invokeMethod('securityOff').then((value) => initVideo(_controller.dataSource));
                              _securityOff = true;
                            } else
                              initAndSetDelegate(widget._link);
                          });
                          return pb();
                        } else if (hasError &&
                            err is PlatformException &&
                            err.message?.contains('MediaCodecVideoRenderer error') == true) {
                          log(TAG, 'trying to play with VLC');
                          initAndSetDelegate(widget._link);
                          return pb();
                        } else if (hasError) return const WidgetChOff();
                        if (!paused) {
                          try {
                            _controller.play();
                          } catch (e) {
                            log(_PlayerState.TAG, 'e=>$e');
                          }
                          if (widget.isTrial) startDemoTimer();
                        }
                        if (!inserted)
                          // widget.db.insert('history', {'title': widget._title, 'link': widget._link, 'logo': widget._logo},
                          //     conflictAlgorithm: ConflictAlgorithm.abort);
                          inserted = true;
                        final size = (_controller as VideoPlayerController).value.size;
                        return Stack(children: [
                          Align(
                              alignment: Alignment.topCenter,
                              child: AspectRatio(
                                  aspectRatio: (size.aspectRatio == 0.0) ? 1.25 : size.aspectRatio,
                                  child: GestureDetector(
                                      onTap: _onScreenTap,
                                      child: Stack(children: [
                                        VideoPlayer(_controller),
                                        if (controlVisible)
                                          Align(
                                              child: IconButton(
                                                  icon: Icon(_controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                                                      color: Colors.white, size: 48),
                                                  onPressed: () {
                                                    if (_controller.value.isPlaying) _controller.pause();
                                                    setState(() {
                                                      paused = !paused;
                                                    });
                                                  }))
                                      ])))),
                          if (fullscreen) miniMaxWidget
                        ]);
                      } else {
                        return pb();
                      }
                    }));
  }

  void _off() {
    if (!mounted) return;
    setState(() => chOff = true);
    // widget._onChannelOff?.call();
  }

  void _onScreenTap() {
    setState(() => controlVisible = true);
    Future.delayed(const Duration(seconds: 2), () => setState(() => controlVisible = false));
  }

  Center pb() => const Center(child: CircularProgressIndicator());

  getName(String link) => link.substring(link.lastIndexOf('/') + 1);

  bool delegate(data) => data.startsWith('rtmp://');

  void repeatedCheck(VlcPlayerController ctr) {
    Future.delayed(const Duration(seconds: 1), ctr.isPlaying).then((isPlaying) {
      log(TAG, 'is playing=>$isPlaying');
      if (isPlaying = true)
        Future.delayed(const Duration(seconds: 2), () {
          setState(() => this.isPlaying = true);
          if (widget.isTrial) startDemoTimer();
        });
      else
        repeatedCheck(ctr);
    });
  }

  void initAndSetDelegate(url) => Future.microtask(() => initVLC(url)).then((value) => setState(() => _delegateToVLC = true));

  void startDemoTimer() => Future.delayed(const Duration(seconds: 3), () => Navigator.pop(context, widget.isTrial));
}

class WidgetChOff extends StatelessWidget {
  const WidgetChOff({
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
