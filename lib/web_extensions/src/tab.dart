import 'dart:async';
import 'dart:html';
import 'dart:js';


class Tab {
  JsObject _js;

  int get id => _js["id"];
  int get windowId => _js["windowId"];
  int get index => _js["index"];
  int get url => _js["url"];


  Tab(this._js){
    if(this._js==null)
      throw new Exception("Tab js object is null");
  }
}