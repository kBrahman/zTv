// ignore_for_file: curly_braces_in_flow_control_structures, constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ztv/model/play_list_info.dart';
import 'package:ztv/model/purchasable_product.dart';
import 'package:ztv/util/util.dart';
import 'package:ztv/util/ztv_purchase.dart';
import 'package:ztv/widget/history_widget.dart';
import 'package:ztv/widget/my_playlists.dart';
import 'package:ztv/widget/player.dart';
import 'package:ztv/widget/playlist_widget.dart';

import 'l10n/locale.dart';

var colorCodes = {
  50: const Color.fromRGBO(247, 0, 15, .1),
  for (var i = 100; i < 1000; i += 100) i: Color.fromRGBO(247, 0, 15, (i + 100) / 1000)
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String data = await rootBundle.loadString('assets/local.properties');
  var iterable = data.split('\n').where((element) => !element.startsWith('#') && element.isNotEmpty);
  var props = {for (var v in iterable) v.split('=')[0]: v.split('=')[1]};
  runApp(Ztv(props['playlist'], props['x_list']));
}

class Ztv extends StatelessWidget {
  static const TAG = 'zTv_Ztv';

  final playlist;
  final xList;

  const Ztv(this.playlist, this.xList, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate
        ],
        supportedLocales: LOCALES,
        localeResolutionCallback: (locale, supportedLocales) => supportedLocales
            .firstWhere((element) => element.languageCode == locale?.languageCode, orElse: () => supportedLocales.first),
        theme: ThemeData(
          primarySwatch: MaterialColor(0XFFF7000F, colorCodes),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomePage(playlist, xList),
      );
}

class HomePage extends StatefulWidget {
  final playlist;
  final xList;

  const HomePage(this.playlist, this.xList, {Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const TAG = '_HomePageState';
  static const YEAR_IN_SEC = 365 * 24 * 3600;
  static const HAS_IPTV = 'has_iptv';

  dynamic _link;
  var _xLink;
  var _dataHolder;
  var _offset = 0.0;
  var _txtFieldTxt;
  var _query;
  var _connectedToInet = true;
  var _filterLanguage = ANY_LANGUAGE;
  var _filterCategory = ANY_CATEGORY;
  var uiState = UIState.MAIN;
  var _title = 'Player';
  final stateStack = [UIState.MAIN];
  List<String> _droDownLanguages = [];
  List<String> _dropDownCategories = [];
  bool? _hasIPTV;
  var purchase = ZtvPurchases();
  String? id;
  late Database db;
  String? _logo;
  List<Widget>? myIPTVPlaylist;
  late VoidCallback _onChannelOff;
  final _myIPTVInfo = PlaylistInfo();
  final _info = PlaylistInfo();

  @override
  void initState() {
    checkConnection();
    hasIPTV();
    initDB();
    super.initState();
  }

  hasIPTV() async {
    var prefs = await SharedPreferences.getInstance();
    await purchase.loadPurchases();
    setState(() {
      _hasIPTV = prefs.getBool(HAS_IPTV) ?? false;
    });
  }

  void _play() {
    if (_link is String && _link == widget.playlist) return;
    _droDownLanguages = [];
    _dropDownCategories = [];
    if (_link == null || _link is List) _link = _txtFieldTxt;
    if (_link == null || _link.trim().isEmpty) return;
    log(TAG, 'play=>$_link');
    if (_connectedToInet && (_link.endsWith('=m3u') || _link.contains('download.php?id') || _link.endsWith('.m3u')))
      setState(() {
        uiState = UIState.PLAYLIST;
        stateStack.add(UIState.PLAYLIST);
      });
    else if (_connectedToInet || isLocalFile(_link))
      setState(() {
        _title = '';
        uiState = UIState.PLAYER;
        stateStack.add(UIState.PLAYER);
      });
    else {
      final snackBar =
          SnackBar(content: Text(AppLocalizations.of(context)?.no_inet ?? 'No internet'), duration: const Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    _txtFieldTxt = _link;
  }

  @override
  Widget build(BuildContext context) => WillPopScope(onWillPop: willPop, child: getChild());

  void _onTap(link, List<Widget> data, double offset, String query, filterLanguage, filterCategory, title, logo, filterLanguages,
      categories, hasFilter, onChannelOff) {
    _onChannelOff = onChannelOff;
    _filterLanguage = filterLanguage;
    _filterCategory = filterCategory;
    _title = title;
    _droDownLanguages = filterLanguages;
    _dropDownCategories = categories;
    _logo = logo;
    _dataHolder = data;
    _offset = offset;
    _query = query;
    setState(() {
      _link = link;
      uiState = UIState.PLAYER;
      stateStack.add(UIState.PLAYER);
    });
    log(TAG, 'on tap, data=>$data');
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
      if (uiState != UIState.PLAYLIST && uiState != UIState.MY_IPTV) {
        _query = null;
        _offset = 0.0;
        _filterLanguage = getLocalizedLanguage(ANY_LANGUAGE, context);
        _filterCategory = getLocalizedCategory(ANY_CATEGORY, context);
        _logo = null;
      }
    });
    return Future.value(false);
  }

  void _browse() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['flac', 'mp4', 'm3u', 'mp3', 'webm']);
    if (result != null) setState(() => _txtFieldTxt = result.files.single.path);
  }

  bool isLocalFile(String link) => link.endsWith('.flac') || link.endsWith('.mp4') || link.endsWith('.mp3');

  Widget getChild() {
    switch (uiState) {
      case UIState.MAIN:
        return Scaffold(
          appBar: AppBar(
            title: const Text('zTv'),
            actions: [
              IconButton(color: Colors.white, icon: const Icon(Icons.history), onPressed: _history),
              IconButton(
                  icon: const Icon(
                    Icons.featured_play_list,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() {
                        uiState = UIState.MY_PLAYLISTS;
                        stateStack.add(UIState.MY_PLAYLISTS);
                      })),
              IconButton(color: Colors.white, icon: const Icon(Icons.folder), onPressed: _browse)
            ],
          ),
          body: Column(
            children: [
              if (_hasIPTV == false && purchase.product != null)
                Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    child: Text(
                        purchase.product!.status == ProductStatus.purchasable
                            ? AppLocalizations.of(context)?.get_iptv_txt(purchase.product!.price, CHANNEL_COUNT) ??
                                'Get $CHANNEL_COUNT channels only for ${purchase.product!.price}/year'
                            : AppLocalizations.of(context)?.processing ?? 'Processing...',
                        style: const TextStyle(fontSize: 14))),
              if (_hasIPTV != null && purchase.product != null)
                TextButton(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(colorCodes[900])),
                    onPressed: () => _hasIPTV! ? myIptv() : buyIptv(false),
                    child: Text(
                        _hasIPTV!
                            ? AppLocalizations.of(context)?.my_iptv ?? 'MY IPTV'
                            : AppLocalizations.of(context)?.buy_iptv ?? 'BUY IPTV',
                        style: const TextStyle(color: Colors.white))),
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
                        decoration:
                            InputDecoration(hintText: AppLocalizations.of(context)?.link_val ?? 'Video URL or IPTV playlist URL'),
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
        return PlaylistWidget(_link, null, _onTap, _offset, _query, _filterLanguage, _filterCategory, _txtFieldTxt,
            _droDownLanguages, _dropDownCategories, true, db, null, _info);
      case UIState.PLAYER:
        return Player(_link.trim(), _title, _logo, db, _onChannelOff);
      case UIState.MY_PLAYLISTS:
        return MyPlaylists(onPlaylistTap, db);
      case UIState.MY_IPTV:
        return PlaylistWidget(_link, _xLink, _onTap, _offset, _query, _filterLanguage, _filterCategory, _txtFieldTxt,
            _droDownLanguages, _dropDownCategories, false, db, (l) => myIPTVPlaylist = l, _myIPTVInfo);
      case UIState.HISTORY:
        return HistoryWidget(db, _historyItemTap);
    }
  }

  Future<void> checkSubs() async {
    setState(() => purchase.product?.status = ProductStatus.pending);
    id = await signIn();
    if (id == null) {
      setState(() {
        _hasIPTV = false;
      });
      return;
    }
    await Firebase.initializeApp();
    var doc = FirebaseFirestore.instance.doc('user/$id');
    doc.get().then((value) {
      var exists = value.exists;
      setState(() {
        _hasIPTV = exists && Timestamp.now().seconds - (value['time'] as Timestamp).seconds < YEAR_IN_SEC;
      });
      if (!_hasIPTV!) buyIptv(true);
      SharedPreferences.getInstance().then((prefs) => prefs.setBool(HAS_IPTV, _hasIPTV!));
    });
  }

  Future<String?> signIn() async {
    GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>['email']);
    id = _googleSignIn.currentUser?.email;
    if (id == null && (id = (await _googleSignIn.signInSilently())?.email) == null) id = (await _googleSignIn.signIn())?.email;
    return Future.value(id);
  }

  buyIptv(bool afterCheckSubs) async {
    if (id == null && !afterCheckSubs) {
      await checkSubs();
    } else if (id == null && afterCheckSubs)
      return;
    else {
      purchase.buy(
          id!,
          () => setState(() {
                _hasIPTV = true;
                SharedPreferences.getInstance().then((value) => value.setBool(HAS_IPTV, _hasIPTV!));
              }),
          () => setState(() => purchase.product?.status = ProductStatus.purchasable));
      setState(() => purchase.product?.status = ProductStatus.pending);
    }
  }

  myIptv() {
    if (myIPTVPlaylist != null)
      _link = myIPTVPlaylist;
    else {
      _link = widget.playlist;
      _xLink = widget.xList;
    }
    setState(() => uiState = UIState.MY_IPTV);
    stateStack.add(UIState.MY_IPTV);
  }

  void checkConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setConnected(connectivityResult);
    Connectivity().onConnectivityChanged.listen((r) {
      if (_hasIPTV == true)
        setState(() => setConnected(r));
      else {
        setConnected(r);
        hasIPTV();
      }
    });
  }

  void setConnected(ConnectivityResult connectivityResult) =>
      _connectedToInet = connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi;

  void _history() => setState(() {
        uiState = UIState.HISTORY;
        stateStack.add(UIState.HISTORY);
      });

  void initDB() async {
    db = await openDatabase(
      p.join(await getDatabasesPath(), DB_NAME),
      onCreate: (db, v) {
        db.execute(CREATE_TABLE_HISTORY);
        db.execute(CREATE_TABLE_PLAYLIST);
      },
      version: 1,
    );
  }

  _historyItemTap(String title, String link, String? logo) {
    setState(() {
      _title = title;
      _link = link;
      _logo = _logo;
      uiState = UIState.PLAYER;
      stateStack.add(uiState);
    });
  }
}

enum UIState { MAIN, PLAYLIST, PLAYER, MY_PLAYLISTS, MY_IPTV, HISTORY }
