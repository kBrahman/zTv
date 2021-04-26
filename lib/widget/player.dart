import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;
  bool fullscreen = false;

  _PlayerState();

  @override
  void initState() {
    var dataSource = widget.linkOrChannel;
    log(TAG, dataSource);
    _controller = VideoPlayerController.network(dataSource is Channel ? dataSource.url : dataSource);
    _initializeVideoPlayerFuture = _controller.initialize();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAudioFile = (widget.linkOrChannel.endsWith('.mp3') || widget.linkOrChannel.endsWith('.flac'));
    return Scaffold(
      backgroundColor: fullscreen ? Colors.black : Colors.white,
      appBar: fullscreen
          ? null
          : AppBar(
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
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final err = snapshot.error;
            if (snapshot.hasError && err is PlatformException && err.message.contains('Source error')) {
              http.Request req = http.Request("Get", Uri.parse(_controller.dataSource))..followRedirects = false;
              http.Client baseClient = http.Client();
              baseClient.send(req).then((resp) => setState(() {
                    _controller = VideoPlayerController.network(resp.headers['location']);
                    _initializeVideoPlayerFuture = _controller.initialize();
                  }));
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError)
              return Center(
                heightFactor: 1,
                child: Text('This channel is offline now. Come later please', textScaleFactor: 1.25),
              );
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
                          child: VideoPlayer(_controller),
                        ),
                        alignment: Alignment.topCenter,
                      ),
                      Positioned(
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
                          )),
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
}
