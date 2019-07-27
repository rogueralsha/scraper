import 'dart:async';
import 'dart:html';
import 'dart:js';


abstract class AJsObject {

  JsObject js;

  AJsObject(this.js) {
    if(this.js==null)
      throw new Exception("AJsObject js object is null");

  }
}
