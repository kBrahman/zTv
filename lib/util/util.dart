// ignore_for_file: constant_identifier_names, avoid_print

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

const LOGIN = 'login';
const UNDEFINED = 'Undefined';
const LAST_SUBS_CHECK_TIME = 'last_subs_check_time';
const HAS_IPTV = 'has_iptv';
const TURKMEN = 'Turkmen';
const ANY_LANGUAGE = 'Any language';
const TAMIL = 'Tamil';
const TURKISH = 'Turkish';
const UKRAINIAN = 'Ukrainian';
const URDU = 'Urdu';
const UZBEK = 'Uzbek';
const VIETNAMESE = 'Vietnamese';
const CASTILIAN = 'Castilian';
const FARSI = 'Farsi';
const GREEK = 'Greek';
const AKAN = 'Akan';
const ALBANIAN = 'Albanian';
const AMHAR = 'Amharic';
const ARABIC = 'Arabic';
const ARMENIAN = 'Armenian';
const ASSYRIAN = 'Assyrian';
const AZERBAIJANI = 'Azerbaijani';
const BASHKIR = 'Bashkir';
const BENGALI = 'Bengali';
const BOSNIAN = 'Bosnian';
const BULGARIAN = 'Bulgarian';
const CATALAN = 'Catalan';
const CHINESE = 'Chinese';
const CROATIAN = 'Croatian';
const CZECH = 'Czech';
const DANISH = 'Danish';
const DUTCH = 'Dutch';
const ENGLISH = 'English';
const ESTONIAN = 'Estonian';
const FAROESE = 'Faroese';
const FINNISH = 'Finnish';
const FRENCH = 'French';
const GALICIAN = 'Galician';
const GEORGIAN = 'Georgian';
const GERMAN = 'German';
const HEBREW = 'Hebrew';
const HINDI = 'Hindi';
const WOLOF = 'Wolof';
const HUNGARIAN = 'Hungarian';
const ICELANDIC = 'Icelandic';
const INDONESIAN = 'Indonesian';
const JAPANESE = 'Japanese';
const ITALIAN = 'Italian';
const JAVANESE = 'Javanese';
const TETUM = 'Tetum';
const KANNADA = 'Kannada';
const KAZAKH = 'Kazakh';
const KHMER = 'Khmer';
const KINYARWANDA = 'Kinyarwanda';
const KOREAN = 'Korean';
const KURDISH = 'Kurdish';
const LAO = 'Lao';
const LATVIAN = 'Latvian';
const LITHUANIAN = 'Lithuanian';
const BURMESE = 'Burmese';
const SWAHILI = 'Swahili';
const OROMO = 'Oromo';
const FRISIAN = 'Frisian';
const WELSH = 'Welsh';
const PAPIAMENTO = 'Papiamento';
const ZAZA = 'Zaza';
const BASQUE = 'Basque';
const LUXEMBOURGISH = 'Luxembourgish';
const IRISH = 'Irish';
const MACEDONIAN = 'Macedonian';
const MALAY = 'Malay';
const MALAYALAM = 'Malayalam';
const MALTESE = 'Maltese';
const MAORI = 'Maori';
const MONGOLIAN = 'Mongolian';
const MONTENEGRIN = 'Montenegrin';
const NEPALI = 'Nepali';
const NORWEGIAN = 'Norwegian';
const PASHTO = 'Pashto';
const SINDHI = 'Sindhi';
const PERSIAN = 'Persian';
const POLISH = 'Polish';
const PORTUGUESE = 'Portuguese';
const PUNJABI = 'Punjabi';
const ROMANIAN = 'Romanian';
const RUSSIAN = 'Russian';
const SERBIAN = 'Serbian';
const SINHALA = 'Sinhala';
const SLOVAK = 'Slovak';
const SLOVENIAN = 'Slovenian';
const SOMALI = 'Somali';
const SPANISH = 'Spanish';
const SUNDANESE = 'Sundanese';
const SWEDISH = 'Swedish';
const TAGALOG = 'Tagalog';
const TELUGU = 'Telugu';
const THAI = 'Thai';
const MALDIVIAN = 'Maldivian';
const KYRGYZ = 'Kyrgyz';
const BELARUSIAN = 'Belarusian';
const BHOJPURI = 'Bhojpuri';
const CHEWA = 'Chewa';
const GREENLANDIC = 'Greenlandic';
const GUJARATI = 'Gujarati';
const INUKTITUT = 'Inuktitut';
const LINGALA = 'Lingala';
const MANDINKA = 'Mandinka';
const MARATHI = 'Marathi';
const ODIA = 'Odia';
const ASSAMESE = 'Assamese';
//categories
const ANY_CATEGORY = 'Any category';
const WEATHER = 'Weather';
const XXX = 'XXX';
const ANIMATION = 'Animation';
const AUTO = 'Auto';
const BUSINESS = 'Business';
const CLASSIC = 'Classic';
const COMEDY = 'Comedy';
const COOKING = 'Cooking';
const CULTURE = 'Culture';
const DOCUMENTARY = 'Documentary';
const EDUCATION = "Education";
const ENTERTAINMENT = 'Entertainment';
const FAMILY = 'Family';
const GENERAL = 'General';
const LEGISLATIVE = 'Legislative';
const LIFESTYLE = 'Lifestyle';
const KIDS = 'Kids';
const LOCAL = 'Local';
const MOVIES = 'Movies';
const MUSIC = 'Music';
const NEWS = 'News';
const OUTDOOR = 'Outdoor';
const RELAX = 'Relax';
const RELIGIOUS = 'Religious';
const SCIENCE = 'Science';
const SERIES = 'Series';
const SHOP = 'Shop';
const SPORTS = 'Sports';
const TRAVEL = 'Travel';

const DB_NAME = 'ztv.db';
const TABLE_PLAYLIST = 'playlist';
const CREATE_TABLE_HISTORY =
    "CREATE TABLE history($COLUMN_ID INTEGER PRIMARY KEY, $COLUMN_TITLE TEXT, $COLUMN_LINK TEXT, $COLUMN_LOGO TEXT, $COLUMN_TIME DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M', 'now', 'localtime')))";
const CREATE_TABLE_PLAYLIST = 'CREATE TABLE playlist($COLUMN_TITLE TEXT, $COLUMN_LINK TEXT PRIMARY KEY)';
const COLUMN_TITLE = 'title';
const COLUMN_LINK = 'link';
const COLUMN_LOGO = 'logo';
const COLUMN_TIME = 'time';
const COLUMN_ID = 'id';
const CHANNEL_COUNT = "6000";
Future<Database>? _dbFuture;
Future<SharedPreferences>? _spFuture;

log(String tag, String? msg) => print('$tag:$msg');

String getLocalizedLanguage(String? s, AppLocalizations? of) {
  switch (s) {
    case null:
    case ANY_LANGUAGE:
      return of?.any_lan ?? ANY_LANGUAGE;
    case WOLOF:
      return of?.wo ?? ANY_LANGUAGE;
    case ODIA:
      return of?.or ?? s!;
    case MALDIVIAN:
      return of?.dv ?? s!;
    case AKAN:
      return of?.ak ?? s!;
    case ALBANIAN:
      return of?.sq ?? s!;
    case AMHAR:
      return of?.am ?? s!;
    case ARABIC:
      return of?.ar ?? s!;
    case ARMENIAN:
      return of?.an ?? s!;
    case ASSYRIAN:
      return of?.aii ?? s!;
    case AZERBAIJANI:
      return of?.az ?? s!;
    case BASHKIR:
      return of?.ba ?? s!;
    case BENGALI:
      return of?.bn ?? s!;
    case BOSNIAN:
      return of?.bo ?? s!;
    case BULGARIAN:
      return of?.bg ?? s!;
    case CATALAN:
      return of?.ca ?? s!;
    case CHINESE:
      return of?.zh ?? s!;
    case CROATIAN:
      return of?.hr ?? s!;
    case CZECH:
      return of?.cz ?? s!;
    case DANISH:
      return of?.da ?? s!;
    case DUTCH:
      return of?.nl ?? s!;
    case ENGLISH:
      return of?.en ?? s!;
    case ESTONIAN:
      return of?.et ?? s!;
    case FAROESE:
      return of?.fo ?? s!;
    case FINNISH:
      return of?.fi ?? s!;
    case FRENCH:
      return of?.fr ?? s!;
    case GALICIAN:
      return of?.gl ?? s!;
    case GEORGIAN:
      return of?.ka ?? s!;
    case GERMAN:
      return of?.de ?? s!;
    case GREEK:
      return of?.el ?? s!;
    case HEBREW:
      return of?.he ?? s!;
    case HINDI:
      return of?.hi ?? s!;
    case HUNGARIAN:
      return of?.hu ?? s!;
    case ICELANDIC:
      return of?.isl ?? s!;
    case INDONESIAN:
      return of?.id ?? s!;
    case ITALIAN:
      return of?.it ?? s!;
    case JAPANESE:
      return of?.ja ?? s!;
    case JAVANESE:
      return of?.jv ?? s!;
    case KANNADA:
      return of?.kn ?? s!;
    case KAZAKH:
      return of?.kk ?? s!;
    case KHMER:
      return of?.km ?? s!;
    case KINYARWANDA:
      return of?.rw ?? s!;
    case KOREAN:
      return of?.ko ?? s!;
    case KURDISH:
      return of?.ku ?? s!;
    case LAO:
      return of?.lo ?? s!;
    case LATVIAN:
      return of?.lv ?? s!;
    case LITHUANIAN:
      return of?.lt ?? s!;
    case LUXEMBOURGISH:
      return of?.lb ?? s!;
    case MACEDONIAN:
      return of?.mk ?? s!;
    case MALAY:
      return of?.ms ?? s!;
    case MALAYALAM:
      return of?.ml ?? s!;
    case MALTESE:
      return of?.mt ?? s!;
    case MAORI:
      return of?.mi ?? s!;
    case MONGOLIAN:
      return of?.mn ?? s!;
    case MONTENEGRIN:
      return of?.cnr ?? s!;
    case NEPALI:
      return of?.ne ?? s!;
    case NORWEGIAN:
      return of?.nn ?? s!;
    case PASHTO:
      return of?.ps ?? s!;
    case PERSIAN:
      return of?.fa ?? s!;
    case POLISH:
      return of?.pl ?? s!;
    case PORTUGUESE:
      return of?.pt ?? s!;
    case PUNJABI:
      return of?.pa ?? s!;
    case ROMANIAN:
      return of?.ro ?? s!;
    case RUSSIAN:
      return of?.ru ?? s!;
    case SERBIAN:
      return of?.sr ?? s!;
    case SINHALA:
      return of?.si ?? s!;
    case SLOVAK:
      return of?.sk ?? s!;
    case SLOVENIAN:
      return of?.sl ?? s!;
    case SOMALI:
      return of?.so ?? s!;
    case SPANISH:
      return of?.es ?? s!;
    case SUNDANESE:
      return of?.su ?? s!;
    case SWEDISH:
      return of?.sv ?? s!;
    case TAGALOG:
      return of?.tl ?? s!;
    case TAMIL:
      return of?.ta ?? s!;
    case TELUGU:
      return of?.te ?? s!;
    case THAI:
      return of?.th ?? s!;
    case TURKISH:
      return of?.tr ?? s!;
    case TURKMEN:
      return of?.tk ?? s!;
    case UKRAINIAN:
      return of?.ua ?? s!;
    case URDU:
      return of?.ur ?? s!;
    case UZBEK:
      return of?.uz ?? s!;
    case VIETNAMESE:
      return of?.vi ?? s!;
    case KYRGYZ:
      return of?.ky ?? s!;
    case BELARUSIAN:
      return of?.be ?? s!;
    case BHOJPURI:
      return of?.bho ?? s!;
    case CHEWA:
      return of?.ny ?? s!;
    case GREENLANDIC:
      return of?.kl ?? s!;
    case GUJARATI:
      return of?.gu ?? s!;
    case INUKTITUT:
      return of?.ui ?? s!;
    case LINGALA:
      return of?.ln ?? s!;
    case MANDINKA:
      return of?.mnk ?? s!;
    case MARATHI:
      return of?.mr ?? s!;
    case ASSAMESE:
      return of?.as ?? s!;
    default:
      return s!;
  }
}

String getLocalizedCategory(String? s, AppLocalizations? of) {
  switch (s) {
    case null:
    case ANY_CATEGORY:
      return of?.any_category ?? ANY_CATEGORY;
    case ANIMATION:
      return of?.anime ?? s!;
    case AUTO:
      return of?.auto ?? s!;
    case BUSINESS:
      return of?.business ?? s!;
    case CLASSIC:
      return of?.classic ?? s!;
    case COMEDY:
      return of?.comedy ?? s!;
    case COOKING:
      return of?.cooking ?? s!;
    case CULTURE:
      return of?.culture ?? s!;
    case DOCUMENTARY:
      return of?.doc ?? s!;
    case EDUCATION:
      return of?.edu ?? s!;
    case ENTERTAINMENT:
      return of?.entertainment ?? s!;
    case FAMILY:
      return of?.family ?? s!;
    case GENERAL:
      return of?.gen ?? s!;
    case KIDS:
      return of?.kids ?? s!;
    case LEGISLATIVE:
      return of?.legislative ?? s!;
    case LIFESTYLE:
      return of?.lifestyle ?? s!;
    case LOCAL:
      return of?.loc ?? s!;
    case MOVIES:
      return of?.mov ?? s!;
    case MUSIC:
      return of?.mus ?? s!;
    case NEWS:
      return of?.news ?? s!;
    case OUTDOOR:
      return of?.outdoor ?? s!;
    case RELAX:
      return of?.relax ?? s!;
    case RELIGIOUS:
      return of?.religious ?? s!;
    case SCIENCE:
      return of?.sci ?? s!;
    case SERIES:
      return of?.series ?? s!;
    case SHOP:
      return of?.shop ?? s!;
    case SPORTS:
      return of?.sports ?? s!;
    case TRAVEL:
      return of?.travel ?? s!;
    case WEATHER:
      return of?.weather ?? s!;
    case UNDEFINED:
      return of?.nan ?? s!;
    default:
      return s!;
  }
}

Future<Database> getDB() async => _dbFuture ??= openDatabase(join(await getDatabasesPath(), DB_NAME), onCreate: (db, v) {
      db.execute(CREATE_TABLE_HISTORY);
      db.execute(CREATE_TABLE_PLAYLIST);
    }, version: 1);

Future<SharedPreferences> getSP() => _spFuture ??= SharedPreferences.getInstance();
