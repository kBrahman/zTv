// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ztv/widget/widget_main.dart';

import '../model/data_purchase.dart';
import '../model/purchasable_product.dart';
import '../util/in_app_purchase.dart';
import '../util/util.dart';
import 'bloc_base.dart';

class MainBloc extends BaseBloc {
  static const _TAG = 'MainBloc';
  static const SEC_PER_YEAR = 365 * Duration.secondsPerDay;
  final _controller = StreamController<Command>();
  final txtCtr = TextEditingController();
  late final SharedPreferences _sp;
  final InAppPurchase _iapConnection = IAPConnection.instance;
  String? login;

  Sink<Command> get cmdSink => _controller.sink;

  late final Stream<PurchaseData?> stream;

  MainBloc() {
    late final StreamSubscription sub;
    sub = _iapConnection.purchaseStream.listen(_onPurchaseUpdate, onDone: () => sub.cancel(), onError: _updateStreamOnError);
    stream = _getStream();
    log(_TAG, 'MainBloc');
  }

  Stream<PurchaseData?> _getStream() async* {
    PurchasableProduct? product;
    _sp = await SharedPreferences.getInstance();
    PurchaseData? data;
    if (_sp.getBool(HAS_IPTV) == true)
      data = const PurchaseData(hasIPTV: true);
    else {
      product = await getProduct();
      if (product != null) data = PurchaseData(price: product.price);
    }
    yield data;
    log(_TAG, 'yield=>$data');
    await for (final cmd in _controller.stream) {
      log(_TAG, 'cmd=>$cmd');
      switch (cmd) {
        case Command.LINK_INVALID:
          yield data = data?.copyWith(linkInvalid: true);
          break;
        case Command.BUY_IPTV:
          if (!BaseBloc.connectedToInet) {
            BaseBloc.globalSink.add(GlobalAction.NO_INET);
            yield data;
            break;
          }
          yield data = data?.copyWith(processing: true);
          yield data = await _buyIptv(data, product!);
          break;
        case Command.MY_IPTV:
          yield const PurchaseData(hasIPTV: true);
          break;
        case Command.SHOW_BUY_IPTV:
          log(_TAG, 'show buy, product=>$product');
          product ??= await getProduct();
          if (product == null) yield null;
          yield PurchaseData(hasIPTV: false, price: product!.price);
          break;
        case Command.ANIM:
          yield data = data?.copyWith(animate: true, scale: 2);
          await Future.delayed(const Duration(milliseconds: 750));
          yield data = data?.copyWith(scale: 1);
      }
    }
  }

  Future<PurchaseData?> _buyIptv(PurchaseData? data, PurchasableProduct product) async {
    log(_TAG, 'buy');
    try {
      login = await _signIn();
      log(_TAG, 'login=>$login');
      if (login == null) return data?.copyWith(processing: false);
      final doc = await FirebaseFirestore.instance.doc('user/$login').get();
      if (doc.exists && Timestamp.now().seconds - (doc['time'] as Timestamp).seconds < SEC_PER_YEAR) {
        _sp.setBool(HAS_IPTV, true);
        return data?.copyWith(hasIPTV: true, processing: false);
      } else if (doc.exists)
        BaseBloc.globalSink.add(GlobalAction.SUB_EXPIRED);
      else
        buy(login!, product);
    } catch (e) {
      log(_TAG, 'e=>$e');
      BaseBloc.globalSink.add(GlobalAction.SIGN_IN_ERR);
      return data?.copyWith(processing: false);
    }
    return data;
  }

  buy(String id, product) {
    final purchaseParam = PurchaseParam(productDetails: product.productDetails);
    _iapConnection.buyConsumable(purchaseParam: purchaseParam);
  }

  Future<String?> _signIn() async {
    log(_TAG, '_signIn');
    GoogleSignIn googleSignIn = GoogleSignIn(scopes: <String>['email']);
    var id = googleSignIn.currentUser?.email;
    if (id == null && (id = (await googleSignIn.signInSilently())?.email) == null) id = (await googleSignIn.signIn())?.email;
    return Future.value(id);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) => purchaseDetailsList.forEach(_handlePurchase);

  void _updateStreamOnError(error) {
    BaseBloc.globalSink.add(GlobalAction.PURCHASE_ERR);
    cmdSink.add(Command.SHOW_BUY_IPTV);
    log(_TAG, 'err=>$error');
  }

  void _handlePurchase(PurchaseDetails purchaseDetails) {
    log(_TAG, '_handlePurchase status=>${purchaseDetails.status}');
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      log(_TAG, 'purchased');
      FirebaseFirestore.instance.doc('user/$login').set({'time': Timestamp.now()}).then((_) {
        _sp.setBool(HAS_IPTV, true);
        cmdSink.add(Command.MY_IPTV);
      });
    } else if (purchaseDetails.status == PurchaseStatus.error || purchaseDetails.status == PurchaseStatus.canceled) {
      log(_TAG, 'pErr=>${purchaseDetails.error?.code}');
      if (purchaseDetails.error?.code != 'purchase_error') BaseBloc.globalSink.add(GlobalAction.PURCHASE_ERR);
      cmdSink.add(Command.SHOW_BUY_IPTV);
    }
    if (purchaseDetails.pendingCompletePurchase) {
      _completePurchase(purchaseDetails);
      log(_TAG, 'complete purchase');
    }
  }

  void _completePurchase(PurchaseDetails purchaseDetails) => _iapConnection.completePurchase(purchaseDetails);

  Future<PurchasableProduct?> getProduct() async {
    final ProductDetailsResponse? response;
    if (!(await _iapConnection.isAvailable()) ||
        (response = await _iapConnection.queryProductDetails({'ztv_channels', 'ztv_channels_product'})).notFoundIDs.length==2)
      return null;
    return response.productDetails.map((e) => PurchasableProduct(e)).toList(growable: false).first;
  }
}

enum Command { BUY_IPTV, MY_IPTV, ANIM, SHOW_BUY_IPTV, LINK_INVALID }
