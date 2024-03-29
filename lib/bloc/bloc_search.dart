// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:ztv/bloc/bloc_base.dart';

class SearchBloc extends BaseBloc<void, SearchState> {
  static const _TAG = 'SearchBloc';

  SearchBloc(bool canSave) {
    (canSave ? BaseBloc.isoRes : BaseBloc.myIptvIsoRes)
        ?.then((r) => ctr.sink.add(SearchState(r.filterLans, r.filterCategories, false)));
  }
}

class SearchState {
  final bool searchActive;
  final Set<String> filterLans;
  final Set<String> filterCategories;

  const SearchState(this.filterLans, this.filterCategories, this.searchActive);
}
