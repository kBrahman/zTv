import 'package:flutter/cupertino.dart';

import '../util/util.dart';

class PlaylistInfo {
  var hasFilter = false;
  List<Widget>? myIPTVPlaylist;
  dynamic linkOrList;
  var isTrial = false;
  String filterLanguage = ANY_LANGUAGE;
  String? filterCategory = ANY_CATEGORY;
  List<String> dropDownLanguages = [];
  List<String> dropDownCategories = [];


  @override
  String toString() {
    return 'PlaylistInfo{linkOrList: $linkOrList}';
  }
}
