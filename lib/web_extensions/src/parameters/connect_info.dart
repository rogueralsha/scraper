@JS()
library connect_info;

import 'package:js/js.dart';

@JS()
@anonymous
class ConnectInfo {
  external String get name;
  external bool get includeTlsChannelId;

  external factory ConnectInfo({String name, bool includeTlsChannelId});
}