import 'package:flutter/material.dart';

class HistoryItem extends StatelessWidget {
  final String name;
  final String link;
  final String? logo;
  final String? time;
  final tap;

  const HistoryItem(this.tap, this.name, this.link, this.logo, this.time, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const img = Image(image: AssetImage('icon/ztv.jpg'));
    return Padding(
        padding: const EdgeInsets.all(4),
        child: GestureDetector(
            onTap: tap,
            child: Row(children: [
              SizedBox(width: 100, child: logo == null ? img : Image.network(logo!, errorBuilder: (c, e, t) => img)),
              Flexible(
                  child: Padding(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(link, style: const TextStyle(fontSize: 13)),
                  Text(time ?? 'unknown')
                ]),
                padding: const EdgeInsets.all(2),
              ))
            ])));
  }
}
