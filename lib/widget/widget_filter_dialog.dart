// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ztv/bloc/bloc_dialog.dart';
import 'package:ztv/ext.dart';
import 'package:ztv/util/util.dart';

class FilterDialog extends StatelessWidget {
  static const _TAG = 'FilterDialog';
  final Set<String> _filterCategories;
  final Set<String> _filterLans;
  final DialogBloc _dialogBloc;
  final DialogState? _currState;

  const FilterDialog(this._dialogBloc, this._filterLans, this._filterCategories, this._currState, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<DialogState>(
        initialData: _currState,
        stream: _dialogBloc.stream,
        builder: (context, snap) {
          log(_TAG, 'state=>${snap.data}');
          log(_TAG, 'filter lans=>$_filterLans');
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
            _dialogBloc.sink
                .add(DialogState(_isLan ? newValue ?? '' : _state.currLan, _isLan ? _state.currCat : newValue ?? ''));
          },
          items: _items.map((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(_isLan
                    ? getLocalizedLanguage(_codeToLan(value, l10n), l10n)
                    : getLocalizedCategory(value.capitalizeFirstLetter(), l10n)));
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

  String? _codeToLan(String value, AppLocalizations? l10n) {
    switch (value) {
      case 'por':
        return l10n?.pt ?? PORTUGUESE;
      case 'bul':
        return l10n?.bg ?? BULGARIAN;
      case 'eng':
        return l10n?.en ?? ENGLISH;
      case 'ukr':
        return l10n?.ua ?? UKRAINIAN;
      case 'spa':
        return l10n?.es ?? SPANISH;
      case 'deu':
        return l10n?.de ?? GERMAN;
      case 'ita':
        return l10n?.it ?? ITALIAN;
      case 'tha':
        return l10n?.th ?? THAI;
      case 'rus':
        return l10n?.ru ?? RUSSIAN;
      case 'nld':
        return l10n?.nl ?? DUTCH;
      case 'ara':
        return l10n?.ar ?? ARABIC;
      case 'hye':
        return l10n?.an ?? ARMENIAN;
      case 'tur':
        return l10n?.tr ?? TURKISH;
      case 'cat':
        return l10n?.ca ?? CATALAN;
      case 'fra':
        return l10n?.fr ?? FRENCH;
      case 'kaz':
        return l10n?.kk ?? KAZAKH;
      case 'ell':
        return l10n?.el ?? GREEK;
      case 'tam':
        return l10n?.ta ?? TAMIL;
      case 'pol':
        return l10n?.pl ?? POLISH;
      case 'hun':
        return l10n?.hu ?? HUNGARIAN;
      case 'yue':
      case 'zho':
        return l10n?.zh ?? CHINESE;
      case 'urd':
        return l10n?.ur ?? URDU;
      case 'hin':
        return l10n?.hi ?? HINDI;
      case 'wol':
        return l10n?.wo ?? WOLOF;
      case 'ben':
        return l10n?.bn ?? BENGALI;
      case 'ron':
        return l10n?.ro ?? ROMANIAN;
      case 'amh':
        return l10n?.am ?? AMHAR;
      case 'ind':
        return l10n?.id ?? INDONESIAN;
      case 'kur':
        return l10n?.ku ?? KURDISH;
      case 'far':
      case 'fas':
        return l10n?.fa ?? PERSIAN;
      case 'pan':
        return l10n?.pa ?? PUNJABI;
      case 'sqi':
        return l10n?.sq ?? ALBANIAN;
      case 'isl':
        return l10n?.isl ?? ICELANDIC;
      case 'tuk':
        return l10n?.tk ?? TURKMEN;
      case 'aze':
        return l10n?.az ?? AZERBAIJANI;
      case 'mal':
        return l10n?.ml ?? MALAYALAM;
      case 'kor':
        return l10n?.ko ?? KOREAN;
      case 'jpn':
        return l10n?.ja ?? JAPANESE;
      case 'msa':
        return l10n?.ms ?? MALAY;
      case 'pus':
        return l10n?.ps ?? PASHTO;
      case 'swe':
        return l10n?.sv ?? SWEDISH;
      case 'ces':
        return l10n?.cz ?? CZECH;
      case 'heb':
        return l10n?.he ?? HEBREW;
      case 'khm':
        return l10n?.km ?? KHMER;
      case 'glg':
      case 'gal':
        return l10n?.gl ?? GALICIAN;
      case 'bos':
        return l10n?.bo ?? BOSNIAN;
      case 'mon':
        return l10n?.mn ?? MONGOLIAN;
      case 'srp':
        return l10n?.sr ?? SERBIAN;
      case 'vie':
        return l10n?.vi ?? VIETNAMESE;
      case 'tgl':
        return l10n?.tl ?? TAGALOG;
      case 'ltz':
        return l10n?.lb ?? LUXEMBOURGISH;
      case 'guj':
        return l10n?.gu ?? GUJARATI;
      case 'nan':
        return l10n?.nan ?? UNDEFINED;
      case 'snd':
        return l10n?.sd ?? SINDHI;
      case 'kan':
        return l10n?.kn ?? KANNADA;
      case 'dan':
        return l10n?.da ?? DANISH;
      case 'fin':
        return l10n?.fi ?? FINNISH;
      case 'est':
        return l10n?.et ?? ESTONIAN;
      case 'lav':
        return l10n?.lv ?? LATVIAN;
      case 'lit':
        return l10n?.lt ?? LITHUANIAN;
      case 'mlt':
        return l10n?.mt ?? MALTESE;
      case 'slk':
        return l10n?.sk ?? SLOVAK;
      case 'gle':
        return l10n?.ga ?? IRISH;
      case 'hrv':
        return l10n?.hr ?? CROATIAN;
      case 'mkd':
        return l10n?.mk ?? MACEDONIAN;
      case 'eus':
        return l10n?.eu ?? BASQUE;
      case 'mar':
        return l10n?.mr ?? MARATHI;
      case 'kat':
        return l10n?.ka ?? GEORGIAN;
      case 'nor':
      case 'nob':
        return l10n?.nn ?? NORWEGIAN;
      case 'sin':
        return l10n?.si ?? SINHALA;
      case 'asm':
        return l10n?.as ?? ASSAMESE;
      case 'ori':
        return l10n?.or ?? ODIA;
      case 'nep':
        return l10n?.ne ?? NEPALI;
      case 'aii':
        return l10n?.aii ?? ASSYRIAN;
      case 'kal':
        return l10n?.kl ?? GREENLANDIC;
      case 'fao':
        return l10n?.fo ?? FAROESE;
      case 'lao':
        return l10n?.lo ?? LAO;
      case 'mya':
        return l10n?.my ?? BURMESE;
      case 'uzb':
        return l10n?.uz ?? UZBEK;
      case 'swa':
        return l10n?.sw ?? SWAHILI;
      case 'orm':
        return l10n?.om ?? OROMO;
      case 'fry':
        return l10n?.fy ?? FRISIAN;
      case 'div':
        return l10n?.dv ?? MALDIVIAN;
      case 'cym':
        return l10n?.cy ?? WELSH;
      case 'som':
        return l10n?.so ?? SOMALI;
      case 'tel':
        return l10n?.te ?? TELUGU;
      case 'bak':
        return l10n?.ba ?? BASHKIR;
      case 'pap':
        return l10n?.pap ?? PAPIAMENTO;
      case 'zza':
        return l10n?.zza ?? ZAZA;
      case 'jav':
        return l10n?.ja ?? JAVANESE;
      case 'tet':
        return l10n?.tet ?? TETUM;
      case 'iku':
        l10n?.ui ?? INUKTITUT;
    }
  }
}
