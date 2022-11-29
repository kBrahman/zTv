// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:ztv/model/isolate_res.dart';
import 'package:ztv/widget/widget_main.dart';

import '../model/channel.dart';
import '../model/isolate_model.dart';
import '../util/util.dart';

abstract class BaseBloc {
  static const _TAG = 'BaseBloc';
  static Future<IsolateRes>? myIptvIsoRes;
  static Future<IsolateRes>? isoRes;
  static var _snackController = StreamController<ToastAction>();
  static const _platform = MethodChannel('ztv.channel/app');
  static bool connectedToInet = true;

  Stream<ToastAction> get snackStream => _snackController.stream;

  static Sink<ToastAction> get snackSink => _snackController.sink;
  static late final String myIPTVLink;
  static late final String lansLink;

  static init(link, lans) async {
    myIPTVLink = link;
    lansLink = lans;
    _platform.setMethodCallHandler(nativeMethodCallHandler);
    connectedToInet = await _platform.invokeMethod('checkConn');
    Firebase.initializeApp();
    myIptvIsoRes = loadChannels(link, lans).catchError(onErr);
    log(_TAG, 'init');
  }

  securityOff() => _platform.invokeMethod('securityOff');

  securityOn() => _platform.invokeMethod('securityOn');

  static void resnack() {
    _snackController = StreamController<ToastAction>();
  }

  static onErr(e) {
    if (e is ClientException) {
      connectedToInet = false;
      snackSink.add(ToastAction.NO_INET);
    }
    return const IsolateRes([], {}, {});
  }

  static Future<dynamic> nativeMethodCallHandler(MethodCall methodCall) async {
    final method = methodCall.method;
    log(_TAG, 'Native method=>$method');
    switch (method) {
      case "onAvailable":
        connectedToInet = true;
        if ((await myIptvIsoRes)?.channels.isEmpty == true) myIptvIsoRes = loadChannels(myIPTVLink, lansLink).catchError(onErr);
        // snackSink.add(ToastAction.ON_INET);
        break;
      case "onLost":
        log(_TAG, 'on lost flutter');
        connectedToInet = false;
    }
  }

  static Future<IsolateRes> loadChannels(String link, lans) async {
    log(_TAG, 'load channels, lans=>$lans');
    final fList = <Future<Response>>[];
    if (link.startsWith('/data/user/0')) return compute(parse, IsolateModel([], File(link).readAsStringSync()));
    fList.add(get(Uri.parse(link)));
    if (lans != null) fList.add(get(Uri.parse(lans)));
    final fResList = await Future.wait(fList);
    const utf8decoder = Utf8Decoder();
    Future<List<Channel>> channelsWithLans = Future.value([]);
    if (fResList.length == 2) channelsWithLans = compute(parseLans, utf8decoder.convert(fResList.last.bodyBytes));
    return compute(parse, IsolateModel(await channelsWithLans, utf8decoder.convert(fResList.first.bodyBytes)));
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
      final channel = Channel(title, link);
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
      for (final ch in channelsWithLans)
        if (ch.url == channel.url) {
          channel.languages.addAll(ch.languages);
          channelsWithLans.remove(ch);
          break;
        }
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
      final channel = Channel(title, link);
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
