import 'package:connectivity/connectivity.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ztv/util/util.dart';
import 'package:ztv/util/ztv_purchase.dart';
import 'package:ztv/widget/my_iptv.dart';
import 'package:ztv/widget/my_playlists.dart';
import 'package:ztv/widget/player.dart';
import 'package:ztv/widget/playlist_widget.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'l10n/locale.dart';

var colorCodes = {
  50: Color.fromRGBO(247, 0, 15, .1),
  for (var i = 100; i < 1000; i += 100) i: Color.fromRGBO(247, 0, 15, (i + 100) / 1000)
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
  String data = await rootBundle.loadString('assets/local.properties');
  var iterable = data.split('\n').where((element) => !element.startsWith('#') && element.isNotEmpty);
  var props = Map.fromIterable(iterable, key: (v) => v.split('=')[0], value: (v) => v.split('=')[1]);
  runApp(Ztv(props['playlist']));
}

class Ztv extends StatelessWidget {
  static const TAG = 'zTv_Ztv';

  final playlist;

  const Ztv(this.playlist);

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate
        ],
        supportedLocales: LOCALES,
        localeResolutionCallback: (locale, supportedLocales) => supportedLocales.firstWhere(
            (element) => element.languageCode == locale?.languageCode,
            orElse: () => supportedLocales.first),
        theme: ThemeData(
          primarySwatch: MaterialColor(0XFFF7000F, colorCodes),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomePage(playlist),
      );
}

class HomePage extends StatefulWidget {
  final playlist;

  const HomePage(this.playlist, {Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const TAG = '_HomePageState';

  var _link;
  var _dataHolder;
  var _offset = 0.0;
  var _txtFieldTxt;
  var _query;
  var _connectedToInet = true;
  var _language = ANY_LANGUAGE;
  var _category = ANY_CATEGORY;
  var uiState = UIState.MAIN;
  var _title = 'Player';
  final stateStack = [UIState.MAIN];
  var _availableLanguages = [ANY_LANGUAGE];
  var _availableCategories = [ANY_CATEGORY];
  var _hasFilter = false;
  var _hasIPTV;

  @override
  void initState() {
    checkConnection();
    checkSubs();
    super.initState();
  }

  void _play() {
    if (_link is String && _link == widget.playlist) return;
    _availableLanguages = [ANY_LANGUAGE];
    _availableCategories = [ANY_CATEGORY];
    if (_link == null || _link is List) _link = _txtFieldTxt;
    if (_link == null || _link.trim().isEmpty) return;
    print('play=>$_link');
    if (_connectedToInet && (_link.endsWith('=m3u') || _link.contains('download.php?id') || _link.endsWith('.m3u')))
      setState(() {
        uiState = UIState.PLAYLIST;
        stateStack.add(UIState.PLAYLIST);
      });
    else if (_connectedToInet || isLocalFile(_link))
      setState(() {
        uiState = UIState.PLAYER;
        stateStack.add(UIState.PLAYER);
      });
    else {
      final snackBar = SnackBar(
          content: Text(AppLocalizations.of(context)?.no_inet ?? 'No internet'), duration: Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    _txtFieldTxt = _link;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: willPop, child: getChild());
  }

  void onTap(urlOrChannel, List<Widget> data, double offset, String query, language, category, title, langs, categories,
      hasFilter) {
    this._language = language;
    this._category = category;
    this._title = title;
    this._availableLanguages = langs;
    this._availableCategories = categories;
    this._hasFilter = hasFilter;
    _dataHolder = data;
    _offset = offset;
    _query = query;
    setState(() {
      _link = urlOrChannel;
      uiState = UIState.PLAYER;
      stateStack.add(UIState.PLAYER);
    });
  }

  void onPlaylistTap(link) => setState(() {
        _link = link;
        uiState = UIState.PLAYLIST;
        stateStack.add(UIState.PLAYLIST);
      });

  Future<bool> willPop() {
    _link = _dataHolder;
    stateStack.removeLast();
    if (stateStack.isEmpty) return Future.value(true);
    setState(() {
      uiState = stateStack.last;
      if (uiState != UIState.PLAYLIST) {
        _query = null;
        _offset = 0.0;
        _language = ANY_LANGUAGE;
        _category = ANY_CATEGORY;
      }
    });
    return Future.value(false);
  }

  void _browse() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['flac', 'mp4', 'm3u', 'mp3', 'm3u']);
    if (result != null)
      setState(() {
        _txtFieldTxt = result.files.single.path;
      });
  }

  bool isLocalFile(String link) => link.endsWith('.flac') || link.endsWith('.mp4') || link.endsWith('.mp3');

  Widget getChild() {
    switch (uiState) {
      case UIState.MAIN:
        return Scaffold(
          appBar: AppBar(
            title: const Text('zTv'),
            actions: [
              IconButton(
                  icon: Icon(
                    Icons.featured_play_list,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() {
                        uiState = UIState.MY_PLAYLISTS;
                        stateStack.add(UIState.MY_PLAYLISTS);
                      })),
              IconButton(color: Colors.white, icon: Icon(Icons.folder), onPressed: _browse)
            ],
          ),
          body: Column(
            children: [
              if (_hasIPTV != null)
                TextButton(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(colorCodes[900])),
                    onPressed: () {
                      _hasIPTV ? myIptv() : buyIptv();
                    },
                    child: Text(_hasIPTV ? 'MY IPTV' : 'BUY IPTV', style: TextStyle(color: Colors.white))),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context)?.link ?? 'Paste your link here',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: TextField(
                        onChanged: (String txt) => _link = txt,
                        decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)?.link_val ?? 'Video URL or IPTV playlist URL'),
                        controller: TextEditingController(text: _txtFieldTxt),
                      )),
                ],
              ))
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _play,
            tooltip: 'Increment',
            child: const Icon(Icons.play_arrow),
          ),
        );
      case UIState.PLAYLIST:
        return PlaylistWidget(_link, onTap, _offset, _query, _language, _category, _txtFieldTxt, _availableLanguages,
            _availableCategories, _hasFilter);
      case UIState.PLAYER:
        return Player(_link.trim(), _title);
      case UIState.MY_PLAYLISTS:
        return MyPlaylists(onPlaylistTap);
      case UIState.MY_IPTV:
        return MyIpTv(
            widget.playlist, onTap, _offset, _query, _language, _category, _availableLanguages, _availableCategories);
    }
  }

  void checkSubs() async {
    ZtvPurchases();
    log(TAG, 'checkSubs');
  }

  myIptv() {
    setState(() {
      uiState = UIState.MY_IPTV;
    });
    stateStack.add(UIState.MY_IPTV);
  }

  buyIptv() {}

  void checkConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    _connectedToInet = connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi;
  }
}

enum UIState { MAIN, PLAYLIST, PLAYER, MY_PLAYLISTS, MY_IPTV }
