import 'package:flutter/material.dart';
import 'package:ztv/bloc/bloc_player.dart';
import 'package:ztv/widget/widget_player.dart';

class HistoryItem extends StatelessWidget {
  final String _title;
  final String _url;
  final String? _logo;
  final String? time;

  const HistoryItem(this._title, this._url, this._logo, this.time, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const img = Image(image: AssetImage('icon/ztv.jpg'));
    return Padding(
        padding: const EdgeInsets.all(4),
        child: GestureDetector(
            onTap: () async {
              final bloc = PlayerBloc(_url, false, _title, _logo, 1.28);
              await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => PlayerWidget(bloc, _title)));
              bloc.dispose();
            },
            child: Row(children: [
              SizedBox(width: 100, child: _logo == null ? img : Image.network(_logo!, errorBuilder: (c, e, t) => img)),
              Flexible(
                  child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(_url, style: const TextStyle(fontSize: 13)),
                        Text(time ?? 'unknown')
                      ])))
            ])));
  }
}
