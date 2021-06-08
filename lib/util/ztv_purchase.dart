import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ztv/model/purchasable_product.dart';
import 'package:ztv/util/util.dart';

import 'in_app_purchase.dart';

class ZtvPurchases extends ChangeNotifier {
  static const TAG = 'ZtvPurchases';

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final iapConnection = IAPConnection.instance;
  var storeState = StoreState.UNDEFINED;
  PurchasableProduct? product;

  late String email;
  var onPurchased;

  ZtvPurchases() {
    log(TAG, 'ZtvPurchases');
    final purchaseUpdated = iapConnection.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );
    loadPurchases();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

// Handle purchases here
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach(_handlePurchase);
  }

  void _handlePurchase(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      log(TAG, 'purchased');
      FirebaseFirestore.instance.doc('user/$email').set({'time': Timestamp.now()}).then((value) => onPurchased());
    }
    if (purchaseDetails.pendingCompletePurchase) {
      iapConnection.completePurchase(purchaseDetails);
    }
  }

  void _updateStreamOnDone() {
    log(TAG, '_updateStreamOnDone');
    _subscription.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    log(TAG, error);
  }

  Future<void> loadPurchases() async {
    final available = await iapConnection.isAvailable();
    if (!available) {
      log(TAG, 'store not available');
      storeState = StoreState.NOT_AVAILABLE;
      notifyListeners();
      return;
    }
    const ids = <String>{'ztv_channels_product'};
    final response = await iapConnection.queryProductDetails(ids);
    response.notFoundIDs.forEach((element) {
      print('Purchase $element not found');
    });
    final products = response.productDetails.map((e) => PurchasableProduct(e)).toList();
    storeState = StoreState.AVAILABLE;
    product = products.first;
    log(TAG, product?.id);
  }

  Future<void> buy(String email, onPurchased) async {
    this.email = email;
    this.onPurchased = onPurchased;
    final purchaseParam = PurchaseParam(productDetails: product!.productDetails);
    await iapConnection.buyConsumable(purchaseParam: purchaseParam);
  }
}

enum StoreState { NOT_AVAILABLE, UNDEFINED, AVAILABLE }
