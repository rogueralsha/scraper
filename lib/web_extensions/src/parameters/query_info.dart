@JS()
library query_info;

import 'package:js/js.dart';

@JS()
@anonymous
class QueryInfo {
  external bool get active;
  external bool get audible;
  external bool get autoDiscardable;
  external String get cookieStoreId ;
  external bool get currentWindow;
  external bool get discarded;
  external bool get hidden;
  external bool get highlighted;
  external int get index;

  external factory QueryInfo({String name, bool includeTlsChannelId});
}