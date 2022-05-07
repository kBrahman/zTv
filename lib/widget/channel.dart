// ignore_for_file: constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ztv/util/util.dart';

class Channel extends StatelessWidget {
  static const TAG = 'Channel';
  final String url;
  final String title;
  final languages = <String>{};
  var categories = <String>{};
  final Function tap;
  var isOff = false;
  ScrollController? sc;
  String query = '';
  var filterLanguage = ANY_LANGUAGE;
  var filterCategory = ANY_CATEGORY;

  String? logo;

  Channel(this.title, this.url, this.tap);

  @override
  Widget build(BuildContext context) {
    const img = Image(image: AssetImage('icon/ztv.jpg'));
    return Padding(
        padding: const EdgeInsets.all(4),
        child: GestureDetector(
          onTap: () => tap(sc?.offset, query, filterLanguage, filterCategory, logo, this),
          child: Card(
            elevation: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: logo == null ? img : Image.network(logo!, errorBuilder: (c, e, t) => img)),
                Text(title, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ));
  }
}
