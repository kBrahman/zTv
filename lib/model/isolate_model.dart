import '../widget/widget_channel.dart';
import 'channel.dart';

class IsolateModel {
  final List<Channel> chs;
  final String data;

  IsolateModel(this.chs, this.data);
}

class IsoModelJson {
  final Map<String?, dynamic> cache;
  final List<dynamic> data;

  IsoModelJson(this.cache, this.data);
}
