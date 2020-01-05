import 'dart:js';

String jsVarDump(dynamic input) => input==null ? "NULL" :
context['JSON'].callMethod('stringify', <dynamic>[input]);

dynamic jsify(dynamic input || input is String) {
  if(input is JsObject) {
    return input;
  } else {
    return new JsObject.jsify(input);
  }
}