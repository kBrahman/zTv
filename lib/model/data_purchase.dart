class PurchaseData {
  final bool hasIPTV;
  final String? price;
  final bool processing;
  final bool animate;
  final double scale;
  final bool linkInvalid;

  const PurchaseData(
      {this.hasIPTV = false,
      this.price,
      this.processing = false,
      this.animate = false,
      this.scale = 1,
      this.linkInvalid = false});

  PurchaseData copyWith({bool? processing, bool? hasIPTV, bool? animate, double? scale, bool? linkInvalid}) => PurchaseData(
      hasIPTV: hasIPTV ?? this.hasIPTV,
      price: price,
      processing: processing ?? this.processing,
      animate: animate ?? this.animate,
      scale: scale ?? this.scale,
      linkInvalid: linkInvalid ?? this.linkInvalid);

  @override
  String toString() {
    return 'PurchaseData{hasIPTV: $hasIPTV, price: $price, processing: $processing, animate: $animate}';
  }
}
