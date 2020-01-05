import 'dart:async';
import 'dart:js';

String jsVarDump(dynamic input) => input==null ? "NULL" :
context['JSON'].callMethod('stringify', <dynamic>[input]);

dynamic jsify(dynamic input) {
  if(input is JsObject || input is String) {
    return input;
  } else {
    return new JsObject.jsify(input);
  }
}

Future<dynamic> awaitPromise(JsObject promise) {
  final completer = new Completer<dynamic>();
  promise.callMethod("then", [
    completer.complete,
    completer.completeError
  ]);
  return completer.future;
}