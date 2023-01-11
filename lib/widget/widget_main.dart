// ignore_for_file: curly_braces_in_flow_control_structures, constant_identifier_names

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ztv/bloc/bloc_main.dart';
import 'package:ztv/bloc/bloc_player.dart';
import 'package:ztv/widget/widget_history.dart';
import 'package:ztv/widget/widget_my_playlists.dart';
import 'package:ztv/widget/widget_player.dart';
import 'package:ztv/widget/widget_playlist.dart';

import '../bloc/bloc_base.dart';
import '../bloc/bloc_my_playlists.dart';
import '../bloc/bloc_playlist.dart';
import '../main.dart';
import '../model/data_purchase.dart';
import '../util/util.dart';

class MainWidget extends StatelessWidget {
  static const _TAG = 'MainWidget';
  final MainBloc _mainBloc;
  String? _title;
  GlobalKey<ScaffoldMessengerState> _messengerKey;

  MainWidget(this._mainBloc, this._messengerKey, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _initGlobalEventListener(context);
    return Scaffold(
        appBar: AppBar(title: const Text('zTv'), actions: [
          IconButton(
              color: Colors.white,
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const HistoryWidget()))),
          IconButton(
              icon: const Icon(Icons.featured_play_list, color: Colors.white),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => MyPlaylists(MyPlaylistsBloc())))),
          IconButton(color: Colors.white, icon: const Icon(Icons.folder), onPressed: _browse)
        ]),
        body: StreamBuilder<PurchaseData?>(
            stream: _mainBloc.stream,
            builder: (c, s) {
              final data = s.data;
              log(_TAG, 'data=>$data');
              final l10n = AppLocalizations.of(context);
              return Column(children: [
                if (data != null)
                  Column(children: [
                    Padding(
                        padding: const EdgeInsets.only(left: 16, right: 4),
                        child: Text(
                            data.processing
                                ? l10n?.processing ?? 'Processing...'
                                : !data.hasIPTV
                                    ? l10n?.get_iptv_txt(data.price!, CHANNEL_COUNT) ??
                                        'Get access to $CHANNEL_COUNT channels only for ${data.price!}/year'
                                    : '',
                            style: const TextStyle(fontSize: 14))),
                    AnimatedScale(
                        duration: const Duration(milliseconds: 750),
                        curve: data.scale == 2 ? Curves.bounceIn : Curves.bounceInOut,
                        scale: data.scale,
                        child: TextButton(
                            style: ButtonStyle(backgroundColor: MaterialStateProperty.all(colorCodes[900])),
                            onPressed: () async =>
                                data.hasIPTV ? _myIPTV(context, false) : _mainBloc.cmdSink.add(Command.BUY_IPTV),
                            child: Text(data.hasIPTV ? l10n?.my_iptv ?? 'MY IPTV' : l10n?.buy_iptv ?? 'BUY IPTV',
                                style: const TextStyle(color: Colors.white)))),
                    if (!data.hasIPTV)
                      GestureDetector(
                          child: Text(l10n?.try_iptv ?? 'TRY FREE', style: const TextStyle(color: Colors.red, fontSize: 12)),
                          onTap: () => _myIPTV(context, true))
                  ]),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(
                            l10n?.link ?? 'Paste your link here',
                            style: Theme.of(context).textTheme.headline5,
                          ),
                          TextField(
                              controller: _mainBloc.txtCtr,
                              decoration: InputDecoration(hintText: l10n?.link_val ?? 'Video URL or IPTV playlist URL')),
                          if (data?.linkInvalid == true)
                            Text(l10n?.invalid_link ?? 'Invalid link', style: const TextStyle(color: Colors.red))
                        ])))
              ]);
            }),
        floatingActionButton: FloatingActionButton(onPressed: () => _play(context), child: const Icon(Icons.play_arrow)));
  }

  _initGlobalEventListener(ctx) {
    log(_TAG, '_snack');
    if (BaseBloc.hasListener) return;
    _mainBloc.globalStream.listen((action) {
      log(_TAG, action.toString());
      final l10n = AppLocalizations.of(ctx);
      switch (action) {
        case GlobalEvent.SIGN_IN_ERR:
          _showSnack(l10n?.sign_in_err ?? 'Could not sign in, try again please', 3);
          break;
        case GlobalEvent.SUB_EXPIRED:
          _showSnack(l10n?.subs_expired ?? 'Your subscription is expired, buy again please', 7);
          break;
        case GlobalEvent.NO_INET:
          _showSnack(l10n?.no_inet ?? 'No internet access', 2);
          break;
        case GlobalEvent.PURCHASE_ERR:
          _showSnack(l10n?.purchase_err ?? 'Could not complete your purchase, try again later please', 2);
          break;
        case GlobalEvent.ON_INET:
          _mainBloc.cmdSink.add(Command.SHOW_BUY_IPTV);
      }
    });
  }

  void _showSnack(String s, dur) {
    log(_TAG, '_showSnack');
    final snackBar = SnackBar(content: Text(s), duration: Duration(seconds: dur));
    _messengerKey.currentState?.showSnackBar(snackBar);
    // ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
  }

  void _browse() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['flac', 'mp4', 'm3u', 'mp3', 'webm', 'opus']);
    final p = result?.files.single.path;
    log(_TAG, 'file picker=>$p');
    if (p != null) {
      _mainBloc.txtCtr.value = TextEditingValue(text: p);
      _title = result?.names.single;
    }
  }

  _myIPTV(context, bool isTrial) async {
    if (!BaseBloc.connectedToInet) {
      BaseBloc.globalSink.add(GlobalEvent.NO_INET);
      return;
    }
    if (await Navigator.push(
            context, MaterialPageRoute(builder: (ctx) => PlaylistWidget(PlaylistBloc(null), null, false, isTrial))) ==
        true) {
      _mainBloc.cmdSink.add(Command.ANIM);
    }
  }

  Future<void> _play(BuildContext context) async {
    final link = _mainBloc.txtCtr.text;
    log(_TAG, 'play=>$link');
    if (link.isEmpty || link == BaseBloc.myIPTVLink) return;
    if (!BaseBloc.connectedToInet)
      BaseBloc.globalSink.add(GlobalEvent.NO_INET);
    else if (!link.startsWith(RegExp(r'https://?|/data/user/0/|rtmp://')))
      _mainBloc.cmdSink.add(Command.LINK_INVALID);
    else if (_isPlaylistLink(link))
      Navigator.push(context, MaterialPageRoute(builder: (context) => PlaylistWidget(PlaylistBloc(link), link, true, false)));
    else {
      final title = _title ?? _getTitle(link);
      final bloc = PlayerBloc(link, false, title, null);
      await Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerWidget(bloc, title)));
      bloc.dispose();
    }
  }

  bool _isPlaylistLink(String link) => link.endsWith('.m3u') || link.endsWith('download.php?id') || link.endsWith('=m3u');

  String _getTitle(String link) => link.substring(link.lastIndexOf('/') + 1);
}

enum GlobalEvent { SIGN_IN_ERR, SUB_EXPIRED, NO_INET, PURCHASE_ERR, ON_INET }
