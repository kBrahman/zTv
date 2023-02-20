// ignore_for_file: constant_identifier_names

import 'package:ztv/util/util.dart';

class Channel {
  static const _TAG = 'Channel';
  final String url;
  final double as;
  late final String title;
  final languages = <String>{};
  final categories = <String>{};
  String? logo;

  Channel(this.url, this.as);
}
