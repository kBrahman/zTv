// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:video_player/video_player.dart';

import '../util/util.dart';
import 'channel.dart';
import 'music_player.dart';

class Player extends StatefulWidget {
  final String _link;
  final String _title;
  final Database db;
  final String? _logo;

  const Player(this._link, this._title, this._logo, this.db, {Key? key}) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  static const TAG = '_PlayerState';
  late dynamic _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool fullscreen = false;
  bool delegateToVLC = false;
  bool isPlaying = false;
  var controlVisible = false;
  bool paused = false;
  var chOff = false;
  bool inserted = false;

  _PlayerState();

  @override
  void initState() {
    var dataSource = widget._link;
    if (dataSource.startsWith('https://59c5c86e10038.streamlock.net'))
      dataSource = dataSource.replaceFirst('59c5c86e10038.streamlock.net', 'panel.dattalive.com');
    delegateToVLC = delegate(dataSource);
    if (delegateToVLC)
      initVLC(dataSource);
    else {
      _controller = VideoPlayerController.network(dataSource);
      _initializeVideoPlayerFuture = _controller.initialize();
    }
    super.initState();
  }

  void initVLC(String url) {
    log(TAG, 'init vlc');
    _controller = VlcPlayerController.network(url, autoPlay: true, options: VlcPlayerOptions())
      ..addOnInitListener(() => repeatedCheck(_controller));
  }

  getUrl(dataSource) => dataSource is Channel ? dataSource.url : dataSource;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAudioFile = (widget._link.endsWith('.mp3') || widget._link.endsWith('.flac'));
    var miniMaxWidget = Positioned(
      bottom: 4,
      right: 4,
      child: IconButton(
          icon: const Icon(
            Icons.fullscreen_exit,
            color: Colors.white,
          ),
          onPressed: () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
              .then((value) => SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values))
              .then((value) => setState(() => fullscreen = false))),
    );

    return Scaffold(
      backgroundColor: fullscreen ? Colors.black : Colors.white,
      appBar: fullscreen
          ? null
          : AppBar(
              leading: const BackButton(),
              title: Text(isAudioFile ? getName(widget._link) : widget._title),
              actions: [
                if (!isAudioFile)
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () => SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top])
                        .then((value) => SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]))
                        .then((value) => setState(() => fullscreen = true)),
                  )
              ],
            ),
      body: chOff
          ? const WidgetChOff()
          : delegateToVLC
              ? Stack(children: [
                  Align(
                      child: GestureDetector(
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
                                        log(TAG, 'is playing=>${_controller.value.isPlaying}');
                                        if (_controller.value.isPlaying) _controller.pause();
                                        setState(() {
                                          paused = !paused;
                                        });
                                      }))
                          ]),
                          onTap: onScreenTap),
                      alignment: Alignment.topCenter),
                  if (fullscreen) miniMaxWidget,
                  if (!isPlaying) pb()
                ])
              : FutureBuilder(
                  future: _initializeVideoPlayerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      final err = snapshot.error;
                      var hasError = snapshot.hasError;
                      final trace = snapshot.stackTrace;
                      if (hasError && err is PlatformException && err.message?.contains('Source error') == true) {
                        log(TAG, 'source err=>$trace, getting location');
                        http.Request req = http.Request("Get", Uri.parse(_controller.dataSource))..followRedirects = false;
                        http.Client baseClient = http.Client();
                        baseClient.send(req).then((resp) {
                          var loc = resp.headers['location'];
                          log(TAG, 'status code=>${resp.statusCode}');
                          log(TAG, 'loc=>$loc');
                          if (loc != null)
                            setState(() {
                              _controller = VideoPlayerController.network(loc);
                              _initializeVideoPlayerFuture = _controller.initialize();
                            });
                          else if (resp.statusCode == 403)
                            setState(() => chOff = true);
                          else
                            initAndSetDelegate(widget._link);
                        }, onError: (e, s) {
                          log(TAG, 'onError=>$e');
                          if (e is SocketException)
                            setState(() => chOff = true);
                          else {
                            log(TAG, 'e=>${e.message}');
                            initAndSetDelegate(widget._link);
                          }
                        });
                        return pb();
                      } else if (hasError &&
                          err is PlatformException &&
                          err.message?.contains('MediaCodecVideoRenderer error') == true) {
                        log(TAG, 'trying to play with VLC');
                        initAndSetDelegate(widget._link);
                        return pb();
                      } else if (hasError) return const WidgetChOff();
                      if (!paused) _controller.play();
                      if (!inserted)
                        widget.db.insert('history', {'title': widget._title, 'link': widget._link, 'logo': widget._logo},
                            conflictAlgorithm: ConflictAlgorithm.abort);
                      inserted = true;
                      final size = _controller.value.size;

                      return isAudioFile
                          ? MusicPlayer(_controller)
                          : Stack(
                              children: [
                                Align(
                                  child: AspectRatio(
                                      aspectRatio: (size == null || size.aspectRatio == 0.0) ? 1.25 : size.aspectRatio,
                                      // Use the VideoPlayer widget to display the video.
                                      child: GestureDetector(
                                          child: Stack(children: [
                                            VideoPlayer(_controller),
                                            if (controlVisible)
                                              Align(
                                                  child: IconButton(
                                                      icon: Icon(
                                                          _controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                                                          color: Colors.white,
                                                          size: 48),
                                                      onPressed: () {
                                                        log(TAG, 'is playing=>${_controller.value.isPlaying}');
                                                        if (_controller.value.isPlaying) _controller.pause();
                                                        setState(() {
                                                          paused = !paused;
                                                        });
                                                      }))
                                          ]),
                                          onTap: onScreenTap)),
                                  alignment: Alignment.topCenter,
                                ),
                                if (fullscreen) miniMaxWidget,
                              ],
                            );
                    } else {
                      return pb();
                    }
                  },
                ),
    );
  }

  void onScreenTap() {
    setState(() => controlVisible = true);
    Future.delayed(const Duration(seconds: 2), () => setState(() => controlVisible = false));
  }

  Center pb() => const Center(child: CircularProgressIndicator());

  getName(String link) => link.substring(link.lastIndexOf('/') + 1);

  bool delegate(data) => data.startsWith('rtmp://');

  void repeatedCheck(VlcPlayerController ctr) {
    Future.delayed(const Duration(seconds: 1), ctr.isPlaying).then((isPlaying) {
      if (isPlaying = true)
        Future.delayed(const Duration(seconds: 2), () => setState(() => this.isPlaying = true));
      else
        repeatedCheck(ctr);
    });
  }

  void initAndSetDelegate(url) => Future.microtask(() => initVLC(url)).then((value) => setState(() => delegateToVLC = true));
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
