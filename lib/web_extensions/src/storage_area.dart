import 'dart:async';
import 'dart:convert';
import 'dart:js';
import 'dart:js_util';

import 'package:logging/logging.dart';

import 'tools.dart';

class StorageArea {
  static final Logger _log = new Logger("StorageArea");
  final JsObject _js;

  StorageArea(this._js) {
    if(this._js==null)
      throw new Exception("StorageArea js object is null");
  }

  Future<Map> get({List<String> keys}) async {
    final List<dynamic> args = <dynamic>[];
    if(keys?.isNotEmpty??false) {
      args.add(jsify(keys));
    }

    _log.finest("storage.get");
    _log.finest(args);

    final dynamic results = await awaitPromise(_js.callMethod("get", args));

    _log.finest(results);
    final jsonData = jsVarDump(results);
    _log.finest(jsonData);

    return json.decode(jsonData);
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