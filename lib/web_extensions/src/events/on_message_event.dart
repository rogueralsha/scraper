import 'dart:async';
import 'dart:html';
import 'dart:js';

import '../message_sender.dart';

class OnMessageEvent {
  final JsObject message;
  final MessageSender sender;
  final JsFunction callback;

  OnMessageEvent(this.message, this.sender, this.callback);

}