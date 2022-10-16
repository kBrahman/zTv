// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';

import '../util/util.dart';

class SearchView extends StatefulWidget {
  final bool _searchActive;
  final Function(String?) _onSearch;
  final _query;

  const SearchView(this._searchActive, this._onSearch, this._query, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late bool _searchActive;
  String? _query;
  late final TextEditingController _ctr;

  // late var ctr;

  @override
  void initState() {
    _query = widget._query;
    _searchActive = widget._searchActive;
    _ctr = TextEditingController(text: _query);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    log(TAG, 'query=>$_query');
    return Row(children: [
      Expanded(
          child: _searchActive
              ? TextField(
                  // key: ValueKey(_query),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (String txt) {
                    widget._onSearch(txt);
                    _query = txt;
                  },
                  controller: _ctr,
                  cursorColor: Colors.white,
                  // controller: TextEditingController(text: widget._query),
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(top: 16),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
                )
              : const SizedBox.shrink()),
      _searchActive
          ? IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
              onPressed: () {
                if (_query?.isNotEmpty == true) widget._onSearch(null);
                setState(() {
                  _searchActive = false;
                  _query = null;
                  _ctr.text = '';
                });
              })
          : IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () => setState(() => _searchActive = true))
    ]);
  }
}
