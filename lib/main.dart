// ignore_for_file: curly_braces_in_flow_control_structures, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ztv/bloc/bloc_base.dart';
import 'package:ztv/widget/widget_main.dart';

import 'bloc/bloc_main.dart';
import 'l10n/locale.dart';
import 'util/util.dart';

final colorCodes = {
  50: const Color.fromRGBO(247, 0, 15, .1),
  for (var i = 100; i < 1000; i += 100) i: Color.fromRGBO(247, 0, 15, (i + 100) / 1000)
};

void main() async {
  const TAG = 'main';
  WidgetsFlutterBinding.ensureInitialized();
  String data = await rootBundle.loadString('assets/local.properties');
  final iterable = data.split('\n').where((element) => !element.startsWith('#') && element.isNotEmpty);
  final props = {for (var v in iterable) v.split('=')[0]: v.split('=')[1]};
  final playlist = props['playlist'];
  final lans = props['lans'];
  BaseBloc.init(playlist, lans);
  runApp(Ztv(playlist, lans));
  log(TAG, 'main');
}

class Ztv extends StatelessWidget {
  static const _TAG = 'Ztv';

  final String? _playlist;
  final String? _lans;
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

   Ztv(this._playlist, this._lans, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    log(_TAG, 'build');
    return MaterialApp(
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
        scaffoldMessengerKey: messengerKey,
        home: _initHome(context, messengerKey));
  }

  _initHome(BuildContext context, GlobalKey<ScaffoldMessengerState> messengerKey) {
    // if (!_snackReady) _snack(context, messengerKey);
    return MainWidget(MainBloc(),messengerKey);
  }
}

//   var _lans;
//   var _dataHolder;
//   var _offset = 0.0;
//   var _txtFieldTxt;
//   String? _query;
//   var _connectedToInet = true;
//   var _uiState = UIState.MAIN;
//   var _title = 'Player';
//   final stateStack = [UIState.MAIN];
//   bool? _hasIPTV;
//   var purchase = ZtvPurchases();
//   String? id;
//   late Database _db;
//   late SharedPreferences _sp;
//   String? _logo;
//   VoidCallback? _onChannelOff;
//   var _myIPTVInfo = PlaylistInfo('myIptvInfo');
//   var _playListInfo = PlaylistInfo('playListInfo');
//   var _scale = 1.0;
//
//   @override
//   void initState() {
//     // init(widget._playlist, widget._listForLans);
//     _initComponents();
//     checkConnection();
//     super.initState();
//   }
//
//   hasIPTV() async {
//     var prefs = await SharedPreferences.getInstance();
//     await purchase.loadPurchases();
//     setState(() => _hasIPTV = prefs.getBool(HAS_IPTV) ?? false);
//   }
//
//   Future<void> _play() async {
//     log(TAG, 'play=>$_playListInfo');
//     if (_playListInfo.linkOrList is String && _playListInfo.linkOrList == widget._playlist) return;
//     _playListInfo.dropDownLanguages = [];
//     _playListInfo.dropDownCategories = [];
//     if (_playListInfo.linkOrList == null || _playListInfo.linkOrList.trim().isEmpty) return;
//     if (_connectedToInet &&
//         (_playListInfo.linkOrList.endsWith('=m3u') ||
//             _playListInfo.linkOrList.contains('download.php?id') ||
//             _playListInfo.linkOrList.endsWith('.m3u')))
//       setState(() {
//         _playListInfo.filterCategory = getLocalizedCategory(_playListInfo.filterCategory, AppLocalizations.of(context));
//         _playListInfo.filterLanguage = getLocalizedLanguage(_playListInfo.filterLanguage, AppLocalizations.of(context));
//         _uiState = UIState.PLAYLIST;
//         stateStack.add(UIState.PLAYLIST);
//       });
//     else if (_connectedToInet || isLocalFile(_playListInfo.linkOrList))
//       setState(() {
//         _title = '';
//         _uiState = UIState.PLAYER;
//         stateStack.add(UIState.PLAYER);
//       });
//     else
//     _txtFieldTxt = _playListInfo.linkOrList;
//   }
//

//
//   @override
//   Widget build(BuildContext context) => WillPopScope(onWillPop: willPop, child: getChild());
//
//   void _onTap(link, List<Widget> data, double offset, String query, filterLanguage, filterCategory, title, logo, filterLanguages,
//       categories, hasFilter, onChannelOff) {
//     _onChannelOff = onChannelOff;
//     _info.filterLanguage = filterLanguage;
//     _info.filterCategory = filterCategory;
//     _title = title;
//     _info.dropDownLanguages = filterLanguages;
//     _info.dropDownCategories = categories;
//     _logo = logo;
//     _dataHolder = data;
//     _offset = offset;
//     _query = query;
//     setState(() {
//       _info.linkOrList = link;
//       _uiState = UIState.PLAYER;
//       stateStack.add(UIState.PLAYER);
//     });
//   }
//
//   PlaylistInfo get _info => stateStack.last == UIState.PLAYLIST ? _playListInfo : _myIPTVInfo;
//
//   void onPlaylistTap(link) => setState(() {
//         _info.linkOrList = link;
//         _uiState = UIState.PLAYLIST;
//         stateStack.add(UIState.PLAYLIST);
//       });
//
//   Future<bool> willPop() {
//     log(TAG, 'will pop, state stack=>$stateStack');
//     _info.linkOrList = _dataHolder;
//     stateStack.removeLast();
//     log(TAG, 'stack empty after remove=>${stateStack.isEmpty}');
//     if (stateStack.isEmpty) return Future.value(true);
//     final last = stateStack.last;
//     log(TAG, 'last=>$last');
//     setState(() {
//       _uiState = last;
//       if (_uiState != UIState.PLAYLIST && _uiState != UIState.MY_IPTV) {
//         _query = null;
//         _offset = 0.0;
//         _info.filterLanguage = getLocalizedLanguage(ANY_LANGUAGE, AppLocalizations.of(context));
//         _info.filterCategory = getLocalizedCategory(ANY_CATEGORY, AppLocalizations.of(context));
//         _logo = null;
//       }
//     });
//     return Future.value(false);
//   }
//
//   void _browse() async {
//     FilePickerResult? result =
//         await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['flac', 'mp4', 'm3u', 'mp3', 'webm']);
//     if (result != null) setState(() => _txtFieldTxt = result.files.single.path);
//   }
//
//   bool isLocalFile(String link) => link.endsWith('.flac') || link.endsWith('.mp4') || link.endsWith('.mp3');
//
//   Widget getChild() {
//     switch (_uiState) {
//       case UIState.MAIN:
//         return Scaffold(
//           appBar: AppBar(
//             title: const Text('zTv'),
//             actions: [
//               IconButton(color: Colors.white, icon: const Icon(Icons.history), onPressed: _history),
//               IconButton(
//                   icon: const Icon(
//                     Icons.featured_play_list,
//                     color: Colors.white,
//                   ),
//                   onPressed: () => setState(() {
//                         _uiState = UIState.MY_PLAYLISTS;
//                         stateStack.add(UIState.MY_PLAYLISTS);
//                       })),
//               IconButton(color: Colors.white, icon: const Icon(Icons.folder), onPressed: _browse)
//             ],
//           ),
//           body: Column(
//             children: [
//               if (_hasIPTV == false && _purchase.product != null)
//                 Padding(
//                     padding: const EdgeInsets.only(left: 4, right: 4),
//                     child: Text(
//                         _purchase.product!.status == ProductStatus.purchasable
//                             ? AppLocalizations.of(context)?.get_iptv_txt(_purchase.product!.price, CHANNEL_COUNT) ??
//                                 'Get $CHANNEL_COUNT channels only for ${_purchase.product!.price}/year'
//                             : AppLocalizations.of(context)?.processing ?? 'Processing...',
//                         style: const TextStyle(fontSize: 14))),
//               if (_hasIPTV != null && _purchase.product != null)
//                 Transform.scale(
//                     scale: _scale,
//                     child: TextButton(
//                         style: ButtonStyle(backgroundColor: MaterialStateProperty.all(colorCodes[900])),
//                         onPressed: () => _hasIPTV! ? myIPTV(false) : buyIptv(false),
//                         child: Text(
//                             _hasIPTV!
//                                 ? AppLocalizations.of(context)?.my_iptv ?? 'MY IPTV'
//                                 : AppLocalizations.of(context)?.buy_iptv ?? 'BUY IPTV',
//                             style: const TextStyle(color: Colors.white)))),
//               if (_hasIPTV == false)
//                 GestureDetector(
//                     child: Text(AppLocalizations.of(context)?.try_iptv ?? 'TRY FREE',
//                         style: const TextStyle(color: Colors.red, fontSize: 12)),
//                     onTap: () => myIPTV(true)),
//               Expanded(
//                   child: Padding(
//                       padding: const EdgeInsets.only(left: 16.0, right: 16.0),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             AppLocalizations.of(context)?.link ?? 'Paste your link here',
//                             style: Theme.of(context).textTheme.headline5,
//                           ),
//                           TextField(
//                             onChanged: (String txt) => _playListInfo.linkOrList = txt,
//                             decoration: InputDecoration(
//                                 hintText: AppLocalizations.of(context)?.link_val ?? 'Video URL or IPTV playlist URL'),
//                             controller: TextEditingController(text: _txtFieldTxt),
//                           ),
//                         ],
//                       )))
//             ],
//           ),
//           floatingActionButton: FloatingActionButton(
//             onPressed: _play,
//             tooltip: 'Increment',
//             child: const Icon(Icons.play_arrow),
//           ),
//         );
//       case UIState.PLAYLIST:
//         return PlaylistWidget(null, _onTap, _offset, _query, _txtFieldTxt, true, _db, _playListInfo, (i) => _playListInfo = i);
//       case UIState.PLAYER:
//         return Player(_info.linkOrList.trim(), _title, _logo, _db, _onChannelOff, _myIPTVInfo.isTrial, _onMain);
//       case UIState.MY_PLAYLISTS:
//         return MyPlaylists(onPlaylistTap, _db);
//       case UIState.MY_IPTV:
//         return PlaylistWidget(_lans, _onTap, _offset, _query, _txtFieldTxt, false, _db, _myIPTVInfo, (i) => _myIPTVInfo = i);
//       case UIState.HISTORY:
//         return HistoryWidget(_db, _historyItemTap);
//     }
//   }
//
//   Future<void> checkSubs() async {
//     setState(() => _purchase.product?.status = ProductStatus.pending);
//     try {
//       id = await _signIn();
//     } catch (e) {
//       showSnack(AppLocalizations.of(context)?.sign_in_err ?? 'Could not sign in, try again please', 3);
//       setState(() => _purchase.product?.status = ProductStatus.purchasable);
//     }
//     if (id == null) {
//       setState(() {
//         _hasIPTV = false;
//         _purchase.product?.status = ProductStatus.purchasable;
//       });
//       return;
//     }
//     try {
//       await Firebase.initializeApp();
//     } catch (e) {
//       showSnack(AppLocalizations.of(context)?.conn_err ?? "Connection error, try again please", 2);
//       setState(() => _purchase.product?.status = ProductStatus.purchasable);
//       return;
//     }
//     var doc = FirebaseFirestore.instance.doc('user/$id');
//     doc.get().then((value) {
//       final exists = value.exists;
//       setState(() {
//         _hasIPTV = exists && Timestamp.now().seconds - (value['time'] as Timestamp).seconds < YEAR_IN_SEC;
//       });
//       if (!_hasIPTV!) buyIptv(true);
//       SharedPreferences.getInstance().then((prefs) {
//         prefs.setBool(HAS_IPTV, _hasIPTV!);
//       });
//     });
//   }
//
//   Future<String?> _signIn() async {
//     GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>['email']);
//     var id = _googleSignIn.currentUser?.email;
//     if (id == null && (id = (await _googleSignIn.signInSilently())?.email) == null) id = (await _googleSignIn.signIn())?.email;
//     return Future.value(id);
//   }
//
//   buyIptv(bool afterCheckSubs) async {
//     if (!afterCheckSubs)
//       await checkSubs();
//     else {
//       _purchase.buy(
//           id!,
//           () => setState(() {
//                 _hasIPTV = true;
//                 SharedPreferences.getInstance().then((value) {
//                   value.setBool(HAS_IPTV, _hasIPTV!);
//                   value.setInt(LAST_SUBS_CHECK_TIME, DateTime.now().millisecondsSinceEpoch);
//                 });
//               }),
//           () => setState(() => _purchase.product?.status = ProductStatus.purchasable));
//       setState(() => _purchase.product?.status = ProductStatus.pending);
//     }
//   }
//
//   myIPTV(bool isTrial) async {
//     _myIPTVInfo.isTrial = isTrial;
//     _myIPTVInfo.filterCategory = getLocalizedCategory(_myIPTVInfo.filterCategory, AppLocalizations.of(context));
//     _myIPTVInfo.filterLanguage = getLocalizedLanguage(_myIPTVInfo.filterLanguage, AppLocalizations.of(context));
//     _myIPTVInfo.linkOrList = _myIPTVInfo.myIPTVPlaylist;
//     if (_myIPTVInfo.linkOrList == null) {
//       _info.linkOrList = widget._playlist;
//       _lans = widget._listForLans;
//     }
//     setState(() => _uiState = UIState.MY_IPTV);
//     stateStack.add(UIState.MY_IPTV);
//
//     if (!isTrial) {
//       final millis = DateTime.now().millisecondsSinceEpoch;
//       final lastCheckTime = _sp.getInt(LAST_SUBS_CHECK_TIME) ?? 0;
//       if (millis - lastCheckTime > 24 * 3600000) {
//         log(_HomePageState.TAG, 'check expired');
//         _sp.setInt(LAST_SUBS_CHECK_TIME, millis);
//         if (!(await FirebaseFirestore.instance.doc('user/$id').get()).exists) {
//           stateStack.removeLast();
//           setState(() {
//             _uiState = stateStack.last;
//             _hasIPTV = false;
//             _purchase.product?.status = ProductStatus.purchasable;
//           });
//           _sp.remove(HAS_IPTV);
//           _sp.remove(LAST_SUBS_CHECK_TIME);
//         }
//       }
//     }
//   }
//
//   void checkConnection() async {
//     var connectivityResult = await (Connectivity().checkConnectivity());
//     setConnected(connectivityResult);
//     Connectivity().onConnectivityChanged.listen((r) {
//       if (_hasIPTV == true)
//         setState(() => setConnected(r));
//       else {
//         setConnected(r);
//         hasIPTV();
//       }
//     });
//   }
//
//   void setConnected(ConnectivityResult connectivityResult) =>
//       _connectedToInet = connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi;
//
//   void _history() => setState(() {
//         _uiState = UIState.HISTORY;
//         stateStack.add(UIState.HISTORY);
//       });
//
//   void _initComponents() async {
//     // await Firebase.initializeApp();
//     _sp = await SharedPreferences.getInstance();
//     _db = await openDatabase(p.join(await getDatabasesPath(), DB_NAME), onCreate: (db, v) {
//       db.execute(CREATE_TABLE_HISTORY);
//       db.execute(CREATE_TABLE_PLAYLIST);
//     }, version: 1);
//   }
//
//   _historyItemTap(String title, String link, String? logo) {
//     setState(() {
//       _title = title;
//       _info.linkOrList = link;
//       _logo = logo;
//       _uiState = UIState.PLAYER;
//       stateStack.add(_uiState);
//     });
//   }
//
//   void _onMain() {
//     setState(() => _uiState = UIState.MAIN);
//     animate(0);
//     stateStack.removeRange(1, stateStack.length);
//   }
//
//   void animate(count) => Future.delayed(const Duration(milliseconds: 250), () {
//         if (count == 4) return;
//         setState(() => _scale = _scale == 1.0 ? 1.3 : 1.0);
//         animate(count + 1);
//       });
