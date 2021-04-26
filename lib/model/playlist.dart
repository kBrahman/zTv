class Playlist {
  final String name;
  final String link;

  Playlist(this.name, this.link);

  Map<String, dynamic> toMap() => {'name': name, 'link': link};
}
