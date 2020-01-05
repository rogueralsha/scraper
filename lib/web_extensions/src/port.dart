@JS("runtime")
library port;

import 'dart:async';
import 'dart:html';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'tools.dart';
import 'message_sender.dart';

@JS()
class Port {

  external String get name;

  external MessageSender get sender;

  final StreamController<Port> _onDisconnectController = new StreamController<Port>.broadcast();

  Stream<Port> get onDisconnect => _onDisconnectController.stream;

  final StreamController<dynamic> _onMessageController = new StreamController<dynamic>.broadcast();

  Stream<dynamic > get onMessage => _onMessageController.stream;


//  Port(this.js):
//        sender = js["sender"]!=null ?  new MessageSender(js["sender"]) : null
//  {
//    if(this.js==null)
//      throw new Exception("Port js object is null");
//
//    js["onDisconnect"].callMethod("addListener", [this.onDisconnectCallback]);
//    js["onMessage"].callMethod("addListener", [this.onMessageCallback]);
//
//  }


  external void disconnect();

//
//  void onDisconnectCallback(JsObject obj) {
//    _onDisconnectController.add(new Port(obj));
//  }
//
//  void onMessageCallback(JsObject obj, JsObject obj2) {
//    _onMessageController.add(obj);
//  }


  external void postMessage(dynamic message);


}