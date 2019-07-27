import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'string_delta.dart';

class DownloadDelta {
  JsObject js;

  int get id => js["id"];
  final StringDelta state;


  DownloadDelta(this.js): this.state = new StringDelta(js["state"]){
    if(this.js==null)
      throw new Exception("DownloadDelta js object is null");

  }
}