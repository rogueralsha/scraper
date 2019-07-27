import 'dart:async';
import 'dart:js';

import 'package:scraper/web_extensions/src/tools.dart';

import 'port.dart';
import 'message_sender.dart';
import 'events/on_message_event.dart';

class Runtime  {
  final JsObject _js;


  final StreamController<Port> _onConnectController = new StreamController<Port>.broadcast();

  Stream<Port> get onConnect => _onConnectController.stream;


  final StreamController<OnMessageEvent> _onMessageController = new StreamController<OnMessageEvent>.broadcast();

  Stream<OnMessageEvent > get onMessage => _onMessageController.stream;


  Runtime(JsObject parent): _js = parent["runtime"]
  {
    if(this._js==null)
      throw new Exception("Runtime js object is null");

    _js["onConnect"]
      .callMethod("addListener", [this.onConnectCallback]);

    _js["onMessage"]
      .callMethod("addListener", [this.onMessageCallback]);
  }

  void onConnectCallback(JsObject obj) {
    _onConnectController.add(new Port(obj));
  }

  void onMessageCallback(JsObject obj, JsObject sender, JsFunction callback) {
    print("onMessageCallback");
    print(jsVarDump(sender));
    _onMessageController.add(new OnMessageEvent(obj, new MessageSender(sender), callback));

  }

  Port connect({String extensionId = null, String name = null, bool includeTlsChannelId = null}) {
    final args = <dynamic>[];

    if(extensionId!=null) {
      args.add(extensionId);
    }

    final connectInfo = <String,dynamic>{};

    if(name!=null) {
      connectInfo["name"] =  name;
    }
    if(includeTlsChannelId!=null) {
      connectInfo["includeTlsChannelId"] =  includeTlsChannelId;
    }

    if(connectInfo.isNotEmpty) {
      args.add(jsify(connectInfo));
    }

    print(args);

    final results = _js.callMethod("connect", args);

    if(results==null) {
      throw new Exception("null returned instead of port");
    }

    print(jsVarDump(results));

    return new Port(results);

  }

  Future<dynamic> sendMessage(dynamic message, {int extensionId = null, bool includeTlsChannelId = null, bool toProxyScript = null}) async {
    List<dynamic> args = [];

    if(extensionId==null) {
      args.add(extensionId);
    }
    args.add(jsify(message));
    args.add(null);

    final Map<String, dynamic> options = <String, dynamic>{};

    if(includeTlsChannelId!=null) {
      options["includeTlsChannelId"] = includeTlsChannelId;
    }
    if(toProxyScript!=null) {
      options["toProxyScript"] = toProxyScript;
    }

    if(options.isNotEmpty) {
      args[args.length-1] = jsify(options);
    }

    final results = await _js.callMethod("sendMessage", args);

    return results;
  }

}