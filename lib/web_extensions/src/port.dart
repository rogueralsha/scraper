import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'tools.dart';
import 'message_sender.dart';

class Port {
  JsObject js;

  String get name => js["name"];
  final MessageSender sender;

  final StreamController<Port> _onDisconnectController = new StreamController<Port>.broadcast();

  Stream<Port> get onDisconnect => _onDisconnectController.stream;

  final StreamController<JsObject> _onMessageController = new StreamController<JsObject>.broadcast();

  Stream<JsObject > get onMessage => _onMessageController.stream;


  Port(this.js):
        sender = js["sender"]!=null ?  new MessageSender(js["sender"]) : null
  {
    if(this.js==null)
      throw new Exception("Port js object is null");

    js["onDisconnect"].callMethod("addListener", [this.onDisconnectCallback]);
    js["onMessage"].callMethod("addListener", [this.onMessageCallback]);

  }

  void disconnect() {
    js.callMethod("disconnect");
  }


  void onDisconnectCallback(JsObject obj) {
    _onDisconnectController.add(new Port(obj));
  }

  void onMessageCallback(JsObject obj, JsObject obj2) {
    _onMessageController.add(obj);
  }


  void postMessage(dynamic message) {
    if(!(message is JsObject)) {
      message = jsify(message);
    }
    js.callMethod("postMessage", [message]);
  }
}