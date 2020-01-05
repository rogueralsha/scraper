@JS()
library tools;

import 'package:js/js.dart';
import 'dart:async';
import 'dart:html_common';

//String jsVarDump(dynamic input) => input==null ? "NULL" :
//context['JSON'].callMethod('stringify', <dynamic>[input]);
//
//

//dynamic jsify(dynamic input) {
//  if(input is JsObject || input is String) {
//    return input;
//  } else {
//    return new JsObject.jsify(input);
//  }
//}
//
//Future<dynamic> callPromisingMethod(JsObject object, String name, List<dynamic> args) async {
//  final dynamic results = await object.callMethod("get", args);
//  return await promiseToFuture(results);
//}

@JS("JSON.stringify")
external String stringify(obj);
