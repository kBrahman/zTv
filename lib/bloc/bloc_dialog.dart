// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:ztv/bloc/bloc_base.dart';
import 'package:ztv/util/util.dart';

class DialogBloc extends BaseBloc {
  static const _TAG = 'DialogBloc';
  final _ctr = StreamController<DialogState>();

  var currState = DialogState(ANY_LANGUAGE, ANY_CATEGORY);

  get sink => _ctr.sink;

  get stream=>_ctr.stream;
  // Stream<DialogState> getStream() async* {
  //   yield currState;
  //   log(_TAG, 'yielded=>$currState');
  //   yield* _ctr.stream.map((state) {
  //     log(_TAG, 'state=>$state');
  //     currState = state;
  //     return state;
  //   });
  // }
}

class DialogState {
  final String currLan;
  final String currCat;

  DialogState(this.currLan, this.currCat);

  @override
  String toString() {
    return 'DialogState{currLan: $currLan, currCat: $currCat}';
  }
}
