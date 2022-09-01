import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ztv/model/play_list_info.dart';

import '../widget/channel.dart';

class IsolateModel {
  final List<Channel> chs;
  final String data;
  final PlaylistInfo info;
  final bool hasSavePlaylist;
  final AppLocalizations? localizations;

  IsolateModel(this.chs, this.data, this.info, this.hasSavePlaylist, this.localizations);

}

class IsolateResponseModel {
  final List<Channel> chs;
  final PlaylistInfo playlistInfo;

  IsolateResponseModel(this.chs, this.playlistInfo);
}
