// ignore_for_file: curly_braces_in_flow_control_structures, constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ztv/model/purchasable_product.dart';
import 'package:ztv/util/util.dart';

import '../bloc/bloc_main.dart';
import '../util/in_app_purchase.dart';

class ZtvPurchase extends ChangeNotifier {
  static const _TAG = 'ZtvPurchases';

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final InAppPurchase _iapConnection = IAPConnection.instance;
  var storeState = StoreState.UNDEFINED;
  late PurchasableProduct product;
  late final SharedPreferences _sp;

  late String login;
  var onPurchased;
  var onPurchaseError;

  ZtvPurchase() {
    log(_TAG, 'ZtvPurchases');
    // final stream = _iapConnection.purchaseStream;
    // _subscription = stream.listen(
    //   _onPurchaseUpdate,
    //   onDone: _updateStreamOnDone,
    //   onError: _updateStreamOnError,
    // );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

// Handle purchases here

  void _updateStreamOnDone() {
    log(_TAG, '_updateStreamOnDone');
    _subscription.cancel();
  }

  Future<void> loadPurchases() async {
    final available = await _iapConnection.isAvailable();
    if (!available) {
      log(_TAG, 'store not available');
      storeState = StoreState.NOT_AVAILABLE;
      notifyListeners();
      return;
    }
    const ids = <String>{'ztv_channels'};
    final response = await _iapConnection.queryProductDetails(ids);
    for (final element in response.notFoundIDs) log(_TAG, 'Purchase $element not found');
    final products = response.productDetails.map((e) => PurchasableProduct(e)).toList();
    storeState = StoreState.AVAILABLE;
    product = products.first;
  }


  buy(String id) {
    login = id;
    try {
      final purchaseParam = PurchaseParam(productDetails: product.productDetails);
      _iapConnection.buyConsumable(purchaseParam: purchaseParam);
    } on Exception catch (e) {
      log(_TAG, 'buyConsumable catch=>$e');
    }
  }

  void completePurchase(PurchaseDetails purchaseDetails) => _iapConnection.completePurchase(purchaseDetails);
}

enum StoreState { NOT_AVAILABLE, UNDEFINED, AVAILABLE }
