import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'tab.dart';

class MessageSender {
  JsObject js;

  final Tab tab;

  MessageSender(this.js):
      this.tab = js.hasProperty("tab") ? new Tab(js["tab"]) : null {

    if(this.js==null)
      throw new Exception("MessageSender js object is null");

  }
}