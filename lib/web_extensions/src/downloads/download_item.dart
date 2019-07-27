import 'dart:async';
import 'dart:html';
import 'dart:js';


class DownloadItem {
  JsObject js;

  String get filename => js["filename"];
  String get error => js["error"];

  DownloadItem(this.js) {
    if(this.js==null)
      throw new Exception("DownloadItem js object is null");

  }
}