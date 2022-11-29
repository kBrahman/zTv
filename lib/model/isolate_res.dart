import 'channel.dart';

class IsolateRes {
  final List<Channel> channels;
  final Set<String> filterCategories;
  final Set<String> filterLans;

  const IsolateRes(this.channels, this.filterCategories, this.filterLans);
}
