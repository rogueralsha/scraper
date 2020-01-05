@JS()
library send_message_options;

import 'package:js/js.dart';

@JS()
@anonymous
class SendMessageOptions {
  external bool get toProxyScript;
  external bool get includeTlsChannelId;

  external factory SendMessageOptions({bool toProxyScript, bool includeTlsChannelId});
}