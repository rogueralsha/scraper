import 'dart:async';
import 'dart:js';

import 'tools.dart';

class StorageArea {
  final JsObject _js;

  StorageArea(this._js) {
    if(this._js==null)
      throw new Exception("StorageArea js object is null");
  }

  Future<Map> get({List<String> keys}) async {
    final args = <dynamic>[jsify(keys)];

    print("storage.get");
    print(jsVarDump(args[0]));

    final JsObject results = await _js.callMethod("get", args);

    print(jsVarDump(results));

    Map<String,dynamic> output = <String,dynamic>{};
    for(var key in keys) {
      output[key] = results[key];
    }

    return output;
  }

  Future<void> set(Map<String,dynamic> keys) async {
    final args = <dynamic>[jsify(keys)];

    await _js.callMethod("set", args);
  }

  Future<void> remove(dynamic keys) async {
    final args = <dynamic>[keys];

    await _js.callMethod("remove", args);
  }
}