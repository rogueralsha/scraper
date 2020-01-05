@JS('browser.storage')
library storage_area;

import 'dart:async';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'storage_area.dart';

@JS()
class Storage {
  external StorageArea get local;
  external StorageArea get sync;

//  Storage(JsObject parent):
//        this._js = parent["storage"],
//        local = new StorageArea(parent["storage"]["local"]),
//        sync = new StorageArea(parent["storage"]["sync"])
//  {
//    if(this._js==null)
//      throw new Exception("Storage js object is null");
//
//  }


}