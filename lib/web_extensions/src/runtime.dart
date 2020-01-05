@JS('browser.runtime')
library runtime;

import 'dart:async';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:logging/logging.dart';

import 'package:scraper/web_extensions/src/tools.dart';

import 'port.dart';
import 'message_sender.dart';
import 'events/on_message_event.dart';
import 'parameters/connect_info.dart';
import 'parameters/send_message_options.dart';

@JS()
class Runtime  {
  static final Logger _log = new Logger("Runtime");
  final StreamController<Port> _onConnectController = new StreamController<Port>.broadcast();

  Stream<Port> get onConnect => _onConnectController.stream;


  final StreamController<OnMessageEvent> _onMessageController = new StreamController<OnMessageEvent>.broadcast();

  Stream<OnMessageEvent > get onMessage => _onMessageController.stream;


//  Runtime()
//  {
//
//
//    if(this._js==null)
//      throw new Exception("Runtime js object is null");
//
//    _js["onConnect"]
//      .callMethod("addListener", [this.onConnectCallback]);
//
//    _js["onMessage"]
//      .callMethod("addListener", [this.onMessageCallback]);
//  }

  external Port connect({String extensionId, ConnectInfo connectInfo});

//  void onConnectCallback(JsObject obj) {
//    _onConnectController.add(new Port(obj));
//  }
//
//  void onMessageCallback(JsObject obj, JsObject sender, JsFunction callback) {
//    _log.finest("onMessageCallback");
//    _log.finest(sender);
//    _onMessageController.add(new OnMessageEvent(obj, new MessageSender(sender), callback));
//
//  }

  Future<dynamic> sendMessage(dynamic message, {String extensionId = null, bool includeTlsChannelId = null, bool toProxyScript = null}) async =>
     await promiseToFuture(_sendMessage(extensionId, message, new SendMessageOptions(toProxyScript: toProxyScript, includeTlsChannelId: includeTlsChannelId)));


  @JS("sendMessage")
  external dynamic _sendMessage(String extensionId, dynamic message, SendMessageOptions options);

//  Future<dynamic> sendMessage(dynamic message, {int extensionId = null, bool includeTlsChannelId = null, bool toProxyScript = null}) async {
//    List<dynamic> args = [];
//
//    if(extensionId==null) {
//      args.add(extensionId);
//    }
//    args.add(jsify(message));
//    args.add(null);
//
//    final Map<String, dynamic> options = <String, dynamic>{};
//
//    if(includeTlsChannelId!=null) {
//      options["includeTlsChannelId"] = includeTlsChannelId;
//    }
//    if(toProxyScript!=null) {
//      options["toProxyScript"] = toProxyScript;
//    }
//
//    if(options.isNotEmpty) {
//      args[args.length-1] = jsify(options);
//    }
//
//    final results = await _js.callMethod("sendMessage", args);
//
//    return results;
//  }

}