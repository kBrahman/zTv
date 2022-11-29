import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ztv/widget/widget_item_history.dart';

import '../util/util.dart';

class HistoryWidget extends StatelessWidget {
  const HistoryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(AppLocalizations.of(context)?.history ?? 'History'),
      ),
      body: FutureBuilder<List<Widget>>(
          future: getHistory(),
          builder: (c, s) => s.connectionState == ConnectionState.done
              ? ListView(children: s.data!)
              : const Center(child: CircularProgressIndicator())));

  Future<List<Widget>> getHistory() async {
    final List<Map<String, dynamic>> maps = await (await getDB()).query('history', orderBy: 'time DESC');
    return List.generate(maps.length, (i) {
      final title = maps[i][COLUMN_TITLE];
      final link = maps[i][COLUMN_LINK];
      final logo = maps[i][COLUMN_LOGO];
      return HistoryItem(title, link, logo, maps[i][COLUMN_TIME]);
    });
  }
}
