// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:ztv/ext.dart';
import 'package:ztv/model/isolate_res.dart';
import 'package:ztv/widget/main_widget.dart';

import '../model/channel.dart';
import '../model/isolate_model.dart';
import '../util/util.dart';

abstract class BaseBloc<D, C> {
  static const _TAG = 'BaseBloc';
  static Future<IsolateRes>? myIptvIsoRes;
  static Future<IsolateRes>? isoRes;
  static final _globalController = StreamController<GlobalEvent>();
  static const _platform = MethodChannel('ztv.channel/app');
  static bool connectedToInet = true;
  final ctr = StreamController<C>();
  late Stream<D> stream;

  Stream<GlobalEvent> get globalStream => _globalController.stream;

  static get hasListener => _globalController.hasListener;

  static Sink<GlobalEvent> get globalSink => _globalController.sink;

  static late final String myIPTVCannelsLink;
  static late final String _streamsLink;

  static init(channels, streams) async {
    myIPTVCannelsLink = channels;
    _streamsLink = streams;
    _platform.setMethodCallHandler(nativeMethodCallHandler);
    _platform.invokeMethod('checkConn').then((value) {
      connectedToInet = value;
      log(_TAG, 'check conn, then v=>$value');
    });
    Firebase.initializeApp();
    try {
      myIptvIsoRes = loadChannels(channels, streams).catchError(onErr);
    } catch (e) {
      log(_TAG, 'catch at loadChannels:$e');
    }
    log(_TAG, 'init');
  }

  securityOff() => _platform.invokeMethod('securityOff');

  securityOn() => _platform.invokeMethod('securityOn');

  static onErr(e) {
    if (e is ClientException) {
      connectedToInet = false;
      globalSink.add(GlobalEvent.NO_INET);
      log(_TAG, 'on err, e=>${e.message}');
    }
    return const IsolateRes([], {}, {});
  }

  static Future<dynamic> nativeMethodCallHandler(MethodCall methodCall) async {
    final method = methodCall.method;
    log(_TAG, 'Native method=>$method');
    switch (method) {
      case "onAvailable":
        connectedToInet = true;
        if ((await myIptvIsoRes)?.channels.isEmpty == true)
          myIptvIsoRes = loadChannels(myIPTVCannelsLink, _streamsLink).catchError(onErr);
        globalSink.add(GlobalEvent.ON_INET);
        break;
      case "onLost":
        log(_TAG, 'on lost flutter');
        connectedToInet = false;
    }
  }

  static Future<IsolateRes> loadChannels(String channelsLink, streamsLink) async {
    final fList = <Future<Response>>[];
    if (channelsLink.startsWith('/data/user/0'))
      return compute(parse, IsolateModel([], File(channelsLink).readAsStringSync()));
    fList.add(get(Uri.parse(channelsLink)));
    if (streamsLink != null) fList.add(get(Uri.parse(streamsLink)));
    final fResList = await Future.wait(fList);
    const utf8decoder = Utf8Decoder();
    Future<Map<String?, dynamic>> channelCache = Future.value({});
    if (fResList.length == 2) channelCache = compute(parseStreams, jsonDecode(utf8decoder.convert(fResList.last.bodyBytes)));
    try {
      return compute(
          parseChannels, IsoModelJson(await channelCache, jsonDecode(utf8decoder.convert(fResList.first.bodyBytes))));
    } catch (e) {
      log(_TAG, 'catch:$e');
    }
    return Future.value();
  }

  static FutureOr<Map<String?, dynamic>> parseStreams(streamsJson) {
    log(_TAG, 'parseStreams');
    final map = <String?, dynamic>{};
    map[null] = <Channel>[];
    for (final m in streamsJson) {
      final id = m['channel'] as String?;
      var url = m['url'];
      if (id == null) {
        final channel = Channel(url, (m['width']?.toDouble() ?? 1.28) / (m['height']?.toDouble() ?? 1));
        channel.title = _getTitle(url);
        (map[null] as List<Channel>).add(channel);
      } else
        map[id] = Channel(url, (m['width']?.toDouble() ?? 1.28) / (m['height']?.toDouble() ?? 1));
    }
    return map;
  }

  static FutureOr<IsolateRes> parseChannels(IsoModelJson model) {
    final cache = model.cache;
    log(_TAG, 'parseChannels, cache size:${cache.length}');
    final channels = [];
    final filterCategories = <String>{};
    final filterLans = <String>{};
    for (final channelMap in model.data) {
      final Channel? channel = cache[channelMap['id']];
      if (channel != null) {
        try {
          channel.title = channelMap['name'];
          channel.logo = channelMap['logo'];
          final categories = (channelMap['categories'] as List<dynamic>?)?.map((e) => e as String);
          if (categories != null) channel.categories.addAll(categories);
          final languages = (channelMap['languages'] as List<dynamic>?)?.map((e) => e as String);
          if (languages != null) channel.languages.addAll(languages);
          channels.add(channel);
          filterCategories.addAll(channel.categories);
          filterLans.addAll(channel.languages);
        } catch (e) {
          log(_TAG, 'catch:$e');
        }
      }
    }
    channels.addAll(cache[null]);
    filterCategories.add(ANY_CATEGORY);
    filterLans.add(ANY_LANGUAGE);
    log(_TAG, 'parseChannels finish');
    return IsolateRes(channels, filterCategories, filterLans);
  }

  static String _getTitle(String url) {
    final splits = url.replaceAll('.m3u8', '').split(RegExp(r'//?'));
    for (final name in splits.skip(1)) if (!name.replaceAll('.', '').isNumeric) return name;
    return 'unknown';
  }
}

IsolateRes parse(IsolateModel model) {
  final lines = model.data.split("\n");
  final channelsWithLans = model.chs;
  final list = <Channel>[];
  final filterCategories = <String>{};
  final filterLans = <String>{};
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('#EXTINF')) {
      final split = line.split(',');
      var title = split.last.replaceAll('====', '');
      String link = lines[++i];
      final endsWith = link.trim().endsWith('.png');
      if (badLink(link)) continue;
      String? category;
      if (link.startsWith('#EXTGRP')) {
        category = link.split(':')[1];
        i++;
      }
      while (!(link = lines[i]).startsWith('http')) {
        i++;
        if (i == lines.length) return const IsolateRes([], {}, {});
      }
      final channel = Channel(link, 1.28);
      channel.title = title;
      if (category != null) channel.categories.add(category);
      if (title.contains(RegExp('FRANCE|\\|FR\\|'))) {
        channel.languages.add(FRENCH);
      } else if (title.contains(RegExp('\\|AR\\|'))) {
        channel.languages.add(ARABIC);
      } else if (title.contains(RegExp('USA|5USA'))) {
        channel.languages.add(ENGLISH);
      } else if (title.contains('NL')) {
        channel.languages.add(DUTCH);
      } else if (link.contains(RegExp('latino|\\|SP\\|'))) {
        channel.languages.add(SPANISH);
      } else if (title.contains(':')) {
        switch (title.split(':').first) {
          case 'FR':
            channel.languages.add(FRENCH);
            break;
          case 'TR':
            channel.languages.add(TURKISH);
            break;
        }
      }
      if (title.contains(RegExp('SPORTS?'))) {
        channel.categories.add(SPORTS);
      } else if (title.contains('News')) {
        channel.categories.add(NEWS);
      } else if (title.contains(RegExp('XXX|Brazzers'))) {
        channel.categories.add(XXX);
      } else if (title.contains(RegExp('BABY|CARTOON|JEUNESSE'))) {
        channel.categories.add(KIDS);
      } else if (title.contains(RegExp('MTV|Music'))) {
        channel.categories.add(MUSIC);
      }
      if (title.toLowerCase().contains('weather')) channel.categories.add(WEATHER);
      var data = split.first;
      // for (final ch in channelsWithLans)
      //   if (ch.url == channel.url) {
      //     channel.languages.addAll(ch.languages);
      //     channelsWithLans.remove(ch);
      //     break;
      //   }
      setChannelProperties(data, channel, false);
      list.add(channel);
      filterCategories.addAll(channel.categories);
      filterLans.addAll(channel.languages);
    }
  }
  filterCategories.add(ANY_CATEGORY);
  filterLans.add(ANY_LANGUAGE);
  log('parse', 'filter cats=>$filterCategories, filter lans=>$filterLans');
  return IsolateRes(list, filterCategories, filterLans);
}

void processItem(String item, Channel channel, bool forLans) {
  String str;
  if (item.startsWith(forLans ? 'group-title' : 'tvg-language') && (str = item.split('=').last).isNotEmpty) {
    channel.languages.addAll(str.split(';'));
    if (channel.languages.contains(CASTILIAN)) {
      channel.languages.remove(CASTILIAN);
      channel.languages.add(SPANISH);
    } else if (channel.languages.contains(FARSI)) {
      channel.languages.remove(FARSI);
      channel.languages.add(PERSIAN);
    } else if (channel.languages.contains('Gernman')) {
      channel.languages.remove('Gernman');
      channel.languages.add(GERMAN);
    } else if (channel.languages.contains('Japan')) {
      channel.languages.remove("Japan");
      channel.languages.add(JAPANESE);
    } else if (channel.languages.contains('CA')) {
      channel.languages.remove('CA');
      channel.languages.add(ENGLISH);
    } else if (channel.languages.any((l) => l.startsWith(RegExp(r'Mandarin|Min|Yue')))) {
      channel.languages.removeWhere((l) => l.startsWith(RegExp(r'Mandarin|Min|Yue')));
      channel.languages.add(CHINESE);
    } else if (channel.languages.contains('Modern')) {
      channel.languages.remove('Modern');
      channel.languages.add(GREEK);
    } else if (channel.languages.contains('News')) {
      channel.languages.remove('News');
      channel.languages.add(ENGLISH);
    } else if (channel.languages.contains('Panjabi')) {
      channel.languages.remove('Panjabi');
      channel.languages.add(PUNJABI);
    } else if (channel.languages.contains('Western')) {
      channel.languages.remove('Western');
      channel.languages.add(DUTCH);
    } else if (channel.languages.contains('Central')) {
      channel.languages.remove('Central');
    } else if (channel.languages.contains('Dhivehi')) {
      channel.languages.remove('Dhivehi');
      channel.languages.add(MALDIVIAN);
    } else if (channel.languages.contains('Kirghiz')) {
      channel.languages.remove('Kirghiz');
      channel.languages.add(KYRGYZ);
    } else if (channel.languages.contains('Letzeburgesch')) {
      channel.languages.remove('Letzeburgesch');
      channel.languages.add(LUXEMBOURGISH);
    } else if (channel.languages.any((element) => element.endsWith('Kurdish'))) {
      channel.languages.removeWhere((e) => e.endsWith('Kurdish'));
      channel.languages.add(KURDISH);
    } else if (channel.languages.contains('Assyrian Neo-Aramaic')) {
      channel.languages.remove('Assyrian Neo-Aramaic');
      channel.languages.add(ASSYRIAN);
    } else if (channel.languages.contains('Norwegian Bokmål')) {
      channel.languages.remove('Norwegian Bokmål');
      channel.languages.add(NORWEGIAN);
    } else if (channel.languages.any((l) => l.startsWith('Oriya'))) {
      channel.languages.removeWhere((l) => l.startsWith('Oriya'));
      channel.languages.add(ODIA);
    }
  } else if (!forLans && item.startsWith('tvg-logo') && (str = item.split('=').last).isNotEmpty) {
    channel.logo = str;
  } else if (!forLans && item.startsWith('group-title') && (str = item.split('=').last).isNotEmpty) {
    channel.categories.addAll(str.split(';').where((element) => element != UNDEFINED));
  }
}

List<Channel> parseLans(String data) {
  final lines = data.split("\n");
  final list = <Channel>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('#EXTINF')) {
      final split = line.split(',');
      var title = split.last.replaceAll('====', '');
      String link = lines[++i];
      if (badLink(link)) continue;
      if (link.startsWith('#EXTGRP')) {
        i++;
      }
      while (!(link = lines[i]).startsWith('http')) i++;
      final channel = Channel(link, 1.28);
      channel.title = title;
      var data = split.first;
      setChannelProperties(data, channel, true);
      list.add(channel);
    }
  }
  return list;
}

setChannelProperties(String s, Channel channel, bool forLans) {
  s = s.replaceAll('#EXTINF:-1 ', '');
  var item = '';
  var quoteCount = 0;
  for (final c in s.characters) {
    if (quoteCount == 2) {
      quoteCount = 0;
      continue;
    }
    if (c == '"')
      quoteCount++;
    else
      item += c;
    if (quoteCount == 2) {
      processItem(item, channel, forLans);
      item = '';
    }
  }
}

bool badLink(link) =>
    link == 'https://d15690s323oesy.cloudfront.net/v1/master/9d062541f2ff39b5c0f48b743c6411d25f62fc25/UDU-Plex/158.m3u8' ||
    link == 'https://sc.id-tv.kz/31Kanal.m3u8' ||
    link == 'https://livelist01.yowi.tv/lista/5e2db2017a8fd03f73b40ede363d1a586db4e9a6/master.m3u8' ||
    link == 'https://livelist01.yowi.tv/lista/eb2fa68a058a701fa5bd2c80f6c8a6075896f71d/master.m3u8' ||
    link == 'http://82.212.74.98:8000/live/7815.m3u8' ||
    link.trim().endsWith('.png');
