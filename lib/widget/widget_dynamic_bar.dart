// ignore_for_file: curly_braces_in_flow_control_structures, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:ztv/bloc/bloc_dialog.dart';
import 'package:ztv/bloc/bloc_playlist.dart';
import 'package:ztv/bloc/bloc_search.dart';
import 'package:ztv/widget/widget_filter_dialog.dart';

import '../util/util.dart';

class DynamicBar extends StatelessWidget {
  static const _TAG = 'DynamicBar';
  final SearchBloc _searchBloc;
  final PlaylistBloc _playlistBloc;
  DialogState? _currState;
  String? q;

  DynamicBar(this._searchBloc, this._playlistBloc, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    log(_TAG, 'build');
    return StreamBuilder<SearchState>(
        initialData: const SearchState({}, {}, false),
        stream: _searchBloc.ctr.stream,
        builder: (context, snap) {
          log(_TAG, 'builder');
          final data = snap.data!;
          final state = SearchState(data.filterLans, data.filterCategories, data.searchActive || q?.isEmpty == false);
          return Row(children: [
            Expanded(
                child: state.searchActive
                    ? TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (String txt) {
                          q = txt;
                          _playlistBloc.ctr.sink
                              .add(FilterEvent(_currState?.currLan ?? ANY_LANGUAGE, _currState?.currCat ?? ANY_CATEGORY, txt));
                        },
                        cursorColor: Colors.white,
                        decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 16),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))))
                    : const SizedBox.shrink()),
            IconButton(
                icon: Icon(state.searchActive ? Icons.close : Icons.search, color: Colors.white),
                onPressed: () {
                  if (state.searchActive) {
                    q = '';
                    _playlistBloc.ctr.sink
                        .add(FilterEvent(_currState?.currLan ?? ANY_LANGUAGE, _currState?.currCat ?? ANY_CATEGORY, ''));
                    _searchBloc.ctr.sink.add(SearchState(state.filterLans, state.filterCategories, false));
                  } else
                    _searchBloc.ctr.sink.add(SearchState(state.filterLans, state.filterCategories, true));
                }),
            if (state.filterCategories.length > 1 || state.filterLans.length > 1)
              IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: () async {
                    final dState = await showDialog(
                        context: context,
                        builder: (ctx) => FilterDialog(DialogBloc(), state.filterLans, state.filterCategories, _currState));
                    if (dState != null) _currState = dState;
                    _playlistBloc.ctr.sink
                        .add(FilterEvent(_currState?.currLan ?? ANY_LANGUAGE, _currState?.currCat ?? ANY_CATEGORY, q ?? ''));
                    log(_TAG, 'dialog res=>$_currState');
                  })
          ]);
        });
  }
}
