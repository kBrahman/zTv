class Channel {
  final String url;
  final String title;
  final languages = <String>{};
  var categories = <String>{};
  String? logo;

  Channel(this.title, this.url);
}
