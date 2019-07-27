import 'dart:async';
import 'dart:html';
import 'dart:js';


class StringDelta {
  JsObject js;

  String get current => js["current"];
  String get previous => js["previous"];


  StringDelta(this.js);
}