import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ztv/util/util.dart';

class Channel extends StatelessWidget {
  static const TAG = 'Channel';
  final String url;
  final String title;
  var languages = [ANY_LANGUAGE];
  var category = ANY_CATEGORY;
  final tap;
  var isOff = false;
  ScrollController? sc;
  String query = '';
  var lan = ANY_LANGUAGE;
  var cat = ANY_CATEGORY;

  String? logo;

  Channel(this.title, this.url, this.tap);

  @override
  Widget build(BuildContext context) {
    var img = const Image(image: AssetImage('icon/ztv.jpg'));
    return Padding(
        padding: const EdgeInsets.all(4),
        child: GestureDetector(
          onTap: () => {tap(url, sc?.offset, query, lan, cat)},
          child: Card(
            elevation: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: logo == null ? img : Image.network(logo!, errorBuilder: (c, e, t) => img)),
                Text(title, style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ));
  }
}
