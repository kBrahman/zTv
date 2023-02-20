// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:ztv/bloc/bloc_base.dart';
import 'package:ztv/bloc/bloc_playlist.dart';
import 'package:ztv/widget/main_widget.dart';
import 'package:ztv/widget/widget_player.dart';

import '../bloc/bloc_player.dart';
import '../model/channel.dart';

class ChannelWidget extends StatelessWidget {
  static const _TAG = 'ChannelWidget';

  final Channel _ch;
  final bool _isTrial;
  final PlaylistBloc _playlistBlock;

  const ChannelWidget(this._ch, this._isTrial, this._playlistBlock, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const img = Image(image: AssetImage('assets/icon/ztv.jpg'));
    return GestureDetector(
        onTap: () async {
          if (!BaseBloc.connectedToInet) {
            BaseBloc.globalSink.add(GlobalEvent.NO_INET);
            return;
          }
          final bloc = PlayerBloc(_ch.url, _isTrial, _ch.title, _ch.logo, _ch.as);
          if ((await Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => PlayerWidget(bloc,_ch.title)))) == true) {
            Navigator.pop(context, _isTrial);
          } else
            _playlistBlock.ctr.sink.add(null);
          bloc.securityOn();
          bloc.dispose();
        },
        child: Card(
            elevation: 4,
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(child: _ch.logo == null ? img : Image.network(_ch.logo!, errorBuilder: (c, e, t) => img)),
              Text(_ch.title, style: const TextStyle(fontSize: 15), maxLines: 3)
            ])));
  }
}
