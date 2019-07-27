import 'dart:js';

String jsVarDump(JsObject input) => input==null ? "NULL" :
context['JSON'].callMethod('stringify', <dynamic>[input]);

JsObject jsify(dynamic input) {
  if(input is JsObject) {
    return input;
  } else {
    return new JsObject.jsify(input);
  }
}