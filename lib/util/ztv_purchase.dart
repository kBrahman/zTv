import 'dart:async';

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

  ZtvPurchases() {
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
    // Handle purchases here
  }

  void _updateStreamOnDone() {
    _subscription.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    log(TAG, error);
  }

  Future<void> loadPurchases() async {
    final available = await iapConnection.isAvailable();
    if (!available) {
      storeState = StoreState.NOT_AVAILABLE;
      notifyListeners();
      return;
    }
    const ids = <String>{'ztv_1'};
    final response = await iapConnection.queryProductDetails(ids);
    response.notFoundIDs.forEach((element) {
      print('Purchase $element not found');
    });
    final products = response.productDetails.map((e) => PurchasableProduct(e)).toList();
    storeState = StoreState.AVAILABLE;
    log(TAG, products.toString());
  }
}

enum StoreState { NOT_AVAILABLE, UNDEFINED, AVAILABLE }
