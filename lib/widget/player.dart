import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:ztv/util/util.dart';
import 'package:ztv/widget/channel.dart';

import 'music_player.dart';

class Player extends StatefulWidget {
  final linkOrChannel;
  final title;

  Player(this.linkOrChannel, this.title);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  static const TAG = '_PlayerState';
  var _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool fullscreen = false;
  bool delegateToVLC = false;
  bool isPlaying = false;
  var controlVisible = false;

  _PlayerState();

  @override
  void initState() {
    var dataSource = widget.linkOrChannel;
    delegateToVLC = delegate(dataSource);
    String url = getUrl(dataSource);
    log(TAG, url.substring(1));
    if (delegateToVLC)
      initVLC(url);
    else {
      _controller = VideoPlayerController.network(url);
      _initializeVideoPlayerFuture = _controller.initialize();
    }
    super.initState();
  }

  void initVLC(String url) {
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
    final isAudioFile = (widget.linkOrChannel.endsWith('.mp3') || widget.linkOrChannel.endsWith('.flac'));
    var miniMaxWidget = Positioned(
        bottom: 4,
        right: 4,
        child: Visibility(
          child: IconButton(
              icon: Icon(
                Icons.fullscreen_exit,
                color: Colors.white,
              ),
              onPressed: () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
                  .then((value) => SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values))
                  .then((value) => setState(() => fullscreen = false))),
          visible: fullscreen,
        ));

    return Scaffold(
      backgroundColor: fullscreen ? Colors.black : Colors.white,
      appBar: fullscreen
          ? null
          : AppBar(
              leading: BackButton(),
              title: Text(isAudioFile ? getName(widget.linkOrChannel) : widget.title),
              actions: [
                isAudioFile
                    ? SizedBox.shrink()
                    : IconButton(
                        icon: Icon(Icons.fullscreen),
                        onPressed: () => SystemChrome.setEnabledSystemUIOverlays([])
                            .then((value) => SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]))
                            .then((value) => setState(() => fullscreen = true)),
                      )
              ],
            ),
      body: delegateToVLC
          ? Stack(children: [
              Align(
                  child: VlcPlayer(
                    controller: _controller,
                    aspectRatio: (_controller.value.size != null && _controller.value.size.aspectRatio != 0.0)
                        ? _controller.value.size.aspectRatio
                        : fullscreen
                            ? .6
                            : 1.7,
                  ),
                  alignment: Alignment.topCenter),
              miniMaxWidget,
              if (!isPlaying) Center(child: CircularProgressIndicator())
            ])
          : FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  final err = snapshot.error;
                  var hasError = snapshot.hasError;
                  if (hasError && err is PlatformException && err.message?.contains('Source error') == true) {
                    log(TAG, 'source err, getting location');
                    http.Request req = http.Request("Get", Uri.parse(_controller.dataSource))..followRedirects = false;
                    http.Client baseClient = http.Client();
                    baseClient.send(req).then((resp) {
                      var loc = resp.headers['location'];
                      if (loc != null)
                        setState(() {
                          _controller = VideoPlayerController.network(loc);
                          _initializeVideoPlayerFuture = _controller.initialize();
                        });
                      else
                        return WidgetChOff();
                    });
                    return Center(child: CircularProgressIndicator());
                  } else if (hasError &&
                      err is PlatformException &&
                      err.message?.contains('MediaCodecVideoRenderer error') == true) {
                    log(TAG, 'trying to play with VLC');
                    delegateToVLC = true;
                    initAndSetDelegate(getUrl(widget.linkOrChannel));
                    return Center(child: CircularProgressIndicator());
                  } else if (hasError) return WidgetChOff();
                  _controller.play();
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
                                                  icon: Icon(Icons.pause, color: Colors.white),
                                                  onPressed: () {
                                                    log(TAG, 'on pressed');
                                                    _controller.pause();
                                                  }))
                                      ]),
                                      onTap: () {
                                        log(TAG, 'tap');
                                        // setState(() => controlVisible = true);
                                        // Future.delayed(Duration(seconds: 1), () => setState(() => controlVisible = false));
                                      })),
                              alignment: Alignment.topCenter,
                            ),
                            miniMaxWidget,
                          ],
                        );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }

  getName(String link) => link.substring(link.lastIndexOf('/') + 1);

  bool delegate(data) => data is String
      ? data.startsWith('rtmp://')
      : data is Channel
          ? data.url.startsWith('rtmp://')
          : false;

  void repeatedCheck(VlcPlayerController ctr) {
    Future.delayed(Duration(seconds: 1), ctr.isPlaying).then((isPlaying) {
      if (isPlaying = true)
        Future.delayed(Duration(seconds: 2), () => setState(() => this.isPlaying = true));
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
    return Center(
      heightFactor: 1,
      child: Text(AppLocalizations.of(context)?.ch_offline ?? 'This channel is offline now. Come later please',
          textScaleFactor: 1.25),
    );
  }
}
