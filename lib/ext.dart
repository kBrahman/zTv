extension StrExt on String {
  bool get isNumeric => num.tryParse(this) != null ? true : false;

  String capitalizeFirstLetter() => "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
}
