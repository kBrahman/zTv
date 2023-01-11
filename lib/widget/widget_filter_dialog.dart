// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ztv/bloc/bloc_dialog.dart';
import 'package:ztv/util/util.dart';

class FilterDialog extends StatelessWidget {
  static const _TAG = 'FilterDialog';
  final Set<String> _filterCategories;
  final Set<String> _filterLans;
  final DialogBloc _dialogBloc;
  final DialogState? _currState;

  const FilterDialog(this._dialogBloc, this._filterLans, this._filterCategories, this._currState, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<DialogState>(
        initialData: _currState,
        stream: _dialogBloc.stream,
        builder: (context, snap) {
          log(_TAG, 'state=>${snap.data}');
          final state = snap.data ?? DialogState(ANY_LANGUAGE, ANY_CATEGORY);
          return AlertDialog(
              title: Padding(
                  padding: const EdgeInsets.only(bottom: 16), child: Text(AppLocalizations.of(context)?.filter ?? 'Filter')),
              contentPadding: const EdgeInsets.only(left: 4, right: 4),
              actions: [
                TextButton(
                    onPressed: () {
                      _dialogBloc.sink.add(DialogState(ANY_LANGUAGE, ANY_CATEGORY));
                    },
                    child: Text(l10n?.reset ?? 'Reset')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context, state);
                    },
                    child: const Text('OK'))
              ],
              content: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: SpinnerAndTitle(_dialogBloc, state, l10n?.language ?? 'Language', _filterLans, true)),
                    Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: SpinnerAndTitle(_dialogBloc, state, l10n?.category ?? 'Category', _filterCategories, false))
                  ])));
        });
  }
}

class SpinnerAndTitle extends StatelessWidget {
  static const _TAG = 'SpinnerAndTitleState';
  final String title;
  final Set<String> _items;
  final DialogState _state;
  final bool _isLan;
  final DialogBloc _dialogBloc;

  const SpinnerAndTitle(this._dialogBloc, this._state, this.title, this._items, this._isLan, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title),
      DropdownButton<String>(
          value: _isLan ? _state.currLan : _state.currCat,
          onChanged: (String? newValue) {
            _dialogBloc.sink.add(DialogState(_isLan ? newValue ?? '' : _state.currLan, _isLan ? _state.currCat : newValue ?? ''));
          },
          items: _items.map((String value) {
            return DropdownMenuItem<String>(
                value: value, child: Text(_isLan ? getLocalizedLanguage(value, l10n) : getLocalizedCategory(value, l10n)));
          }).toList(growable: false)
            ..sort(_isLan ? _compareLan : _compareCat))
    ]);
  }

  int _compareLan(DropdownMenuItem<String> e1, DropdownMenuItem<String> e2) {
    final v1 = (e1.child as Text).data;
    final v2 = (e2.child as Text).data;
    if (v1 == null || v2 == null)
      return v1 == null
          ? v2 == null
              ? 0
              : 1
          : -1;

    return e1.value == ANY_LANGUAGE
        ? -1
        : e2.value == ANY_LANGUAGE
            ? 1
            : v1.compareTo(v2);
  }

  int _compareCat(DropdownMenuItem<String> e1, DropdownMenuItem<String> e2) {
    final v1 = (e1.child as Text).data;
    final v2 = (e2.child as Text).data;
    if (v1 == null || v2 == null)
      return v1 == null
          ? v2 == null
              ? 0
              : 1
          : -1;

    return e1.value == ANY_CATEGORY || e2.value == 'XXX'
        ? -1
        : e2.value == ANY_CATEGORY || e1.value == 'XXX'
            ? 1
            : v1.compareTo(v2);
  }
}
