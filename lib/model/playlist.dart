import 'package:ztv/util/util.dart';

class Playlist {
  final String name;
  final String link;

  const Playlist(this.name, this.link);

  Map<String, dynamic> toMap() => {COLUMN_TITLE: name, COLUMN_LINK: link};
}
