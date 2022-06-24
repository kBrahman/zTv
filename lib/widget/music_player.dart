import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

class MusicPlayer extends StatefulWidget {
  final VideoPlayerController _controller;

  MusicPlayer(this._controller);

  @override
  State<StatefulWidget> createState() => MusicPlayerState();
}

class MusicPlayerState extends State<MusicPlayer> {
  var progress = 0.0;
  var isPlaying = true;
  var deactivated = false;

  @override
  void initState() {
    setProgress();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Center(
              child: Text(
            AppLocalizations.of(context)?.audio ?? 'This is an audio file!',
            style: const TextStyle(fontSize: 24),
          )),
          Padding(
            padding: EdgeInsets.all(4),
            child: Row(
              children: [
                IconButton(
                    icon: Icon(widget._controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      widget._controller.value.isPlaying ? widget._controller.pause() : widget._controller.play();
                      setState(() => widget._controller.value.isPlaying);
                    }),
                Expanded(
                    child: Slider(
                        value: progress,
                        activeColor: Colors.black,
                        onChanged: (v) => setState(() {
                              progress = v;
                              widget._controller
                                  .seekTo(Duration(milliseconds: (v * widget._controller.value.duration.inMilliseconds).toInt()));
                            })))
              ],
            ),
          )
        ],
      );

  Future<Void> setProgress() {
    if (deactivated) return Future.value();
    if (progress == 1) {
      progress = 0;
      widget._controller.pause();
      widget._controller.seekTo(const Duration(seconds: 0));
    }
    setState(() => progress =
        widget._controller.value.position.inMilliseconds.toDouble() / widget._controller.value.duration.inMilliseconds);
    return Future.delayed(const Duration(seconds: 1), setProgress);
  }

  @override
  void deactivate() {
    deactivated = true;
    super.deactivate();
  }
}
