// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:ztv/bloc/bloc_base.dart';

class SearchBloc extends BaseBloc {
  static const _TAG = 'SearchBloc';

  final _ctr = StreamController<SearchState>();

  SearchBloc(bool canSave) {
    (canSave ? BaseBloc.isoRes : BaseBloc.myIptvIsoRes)
        ?.then((r) => sink.add(SearchState(r.filterLans, r.filterCategories, false)));
  }

  Stream<SearchState> get stream => _ctr.stream;

  Sink<SearchState> get sink => _ctr.sink;
}

class SearchState {
  final bool searchActive;
  final Set<String> filterLans;
  final Set<String> filterCategories;

  const SearchState(this.filterLans, this.filterCategories, this.searchActive);
}
