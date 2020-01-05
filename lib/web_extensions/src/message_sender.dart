@JS("runtime")
library message_sender;

import 'package:js/js.dart';

import 'dart:async';
import 'dart:html';

import 'tab.dart';

@JS()
class MessageSender {
  external Tab get tab;

//  MessageSender(this.js):
//      this.tab = js.hasProperty("tab") ? new Tab(js["tab"]) : null {
//
//    if(this.js==null)
//      throw new Exception("MessageSender js object is null");
//
//  }
}