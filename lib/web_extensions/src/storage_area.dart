@JS('storage')
library storage_area;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:logging/logging.dart';

import 'tools.dart';

@JS()
class StorageArea {
  static final Logger _log = new Logger("StorageArea");

//  StorageArea(this._js) {
//    if (this._js == null)
//      throw new Exception("StorageArea js object is null");
//  }

  Future<Map<String, dynamic>> get({List<String> keys}) async {
    _log.finest("storage.get");
    _log.finest(keys);

    final dynamic results = await promiseToFuture(_get(keys));
    _log.finest(results);
    return results;
  }

  @JS("get")
  external dynamic _get(List<String> keys);

  Future<void> remove(List<String> keys) async {
    final List<dynamic> args = <dynamic>[keys];

    await promiseToFuture(_remove(keys));
  }

  @JS("remove")
  external dynamic _remove(List<String> keys);

  Future<void> set(Map<String, dynamic> keys) async {
    final List<dynamic> args = <dynamic>[jsify(keys)];

    await promiseToFuture(_set(keys));
  }

  @JS("set")
  external dynamic _set(Map<String, dynamic> keys);
}
