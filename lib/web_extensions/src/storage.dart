import 'dart:async';
import 'dart:js';

import 'storage_area.dart';

class Storage {
  final JsObject _js;
  final StorageArea local;
  final StorageArea sync;

  Storage(JsObject parent):
        this._js = parent["storage"],
        local = new StorageArea(parent["storage"]["local"]),
        sync = new StorageArea(parent["storage"]["sync"])
  {
    if(this._js==null)
      throw new Exception("Storage js object is null");

  }


}