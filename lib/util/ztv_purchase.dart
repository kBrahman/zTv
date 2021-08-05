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
  final InAppPurchase iapConnection = IAPConnection.instance;
  var storeState = StoreState.UNDEFINED;
  PurchasableProduct? product;

  late String id;
  var onPurchased;
  var onPurchaseError;

  ZtvPurchases() {
    log(TAG, 'ZtvPurchases');
    final stream = iapConnection.purchaseStream;
    _subscription = stream.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );
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
    log(TAG, '_handlePurchase status=>${purchaseDetails.status}');
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      log(TAG, 'purchased');
      FirebaseFirestore.instance.doc('user/$id').set({'time': Timestamp.now()}).then((_) => onPurchased());
    } else if (purchaseDetails.status == PurchaseStatus.error) onPurchaseError();
    if (purchaseDetails.pendingCompletePurchase) {
      iapConnection.completePurchase(purchaseDetails);
      log(TAG,'complete purchase');
    }
  }

  void _updateStreamOnDone() {
    log(TAG, '_updateStreamOnDone');
    _subscription.cancel();
  }

  void _updateStreamOnError(error) {
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
    const ids = <String>{'ztv_channels'};
    final response = await iapConnection.queryProductDetails(ids);
    response.notFoundIDs.forEach((element) {
      print('Purchase $element not found');
    });
    final products = response.productDetails.map((e) => PurchasableProduct(e)).toList();
    storeState = StoreState.AVAILABLE;
    product = products.first;
    log(TAG, product?.id);
  }

  buy(String id, onPurchased, onPurchaseError) {
    this.id = id;
    this.onPurchased = onPurchased;
    this.onPurchaseError = onPurchaseError;
    final purchaseParam = PurchaseParam(productDetails: product!.productDetails);
    try {
      iapConnection.buyConsumable(purchaseParam: purchaseParam);
    } on Exception catch (e) {
      log(TAG, 'buyConsumable catch=>$e');
    }
  }
}

enum StoreState { NOT_AVAILABLE, UNDEFINED, AVAILABLE }
