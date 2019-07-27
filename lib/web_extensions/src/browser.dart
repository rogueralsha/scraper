import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:scraper/globals.dart';

import 'downloads.dart';
import 'runtime.dart';
import 'storage.dart';
import 'tabs.dart';

class Browser {
  final js.JsObject _js;

  final Downloads downloads;
  final Runtime runtime;
  final Storage storage;
  final Tabs tabs;

  Browser():
        _js = js.context["browser"],
        downloads = (js.context["browser"] as js.JsObject).hasProperty("downloads") ? new Downloads(js.context["browser"]) : null,
        runtime = new Runtime(js.context["browser"]),
        storage = new Storage(js.context["browser"]),
        tabs = (js.context["browser"] as js.JsObject).hasProperty("tabs") ? new Tabs(js.context["browser"]) : null
  {
    print(jsVarDump(_js));

    if(this._js==null)
      throw new Exception("Browser js object is null");

  }
}


