import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:scraper/globals.dart';

import 'tools.dart';
import 'tab.dart';
import 'port.dart';

class Tabs {
  final JsObject _js;

  Tabs(JsObject parent): _js = parent["tabs"] {
    if(this._js==null)
      throw new Exception("Tabs js object is null");
  }

  Future<List<Tab>> query({bool active = null, int windowId = null, bool currentWindow = null}) async {
    var args = {};

    if(active!=null) {
      args["active"] = active;
    }
    if(windowId!=null) {
      args["windowId"] = windowId;
    }
    if(currentWindow!=null) {
      args["currentWindowOptional"] = currentWindow;
    }

    final output = <Tab>[];
    final results = await _js.callMethod("query", [args]);
    for(var result in results) {
      output.add(new Tab(result));
    }

    return output;
  }

  Future<dynamic> sendMessage(int tabId, dynamic message, {int frameId = null}) async {
    var args = [tabId, jsify(message), null];


    var options= {};

    if(frameId!=null) {
      options["frameId"] = frameId;
    }

    if(options.isNotEmpty) {
      args[2] = jsify(options);
    }

    final results = await _js.callMethod("sendMessage", args);

    return results;
  }

  Future<void> remove(int tabId) async {
    await _js.callMethod("remove", [tabId]);
  }

  Port connect(int tabId, {String name = null, int frameId = null}) {
    var args = <dynamic>[tabId];

    var connectInfo = {};

    if(name!=null) {
      connectInfo["name"] =  name;
    }
    if(frameId!=null) {
      connectInfo["frameId"] =  frameId;
    }

    if(connectInfo.isNotEmpty) {
      args.add(jsify(connectInfo));
    }

    final results = _js.callMethod("connect", args);

    return new Port(results);

  }

  Future<Tab> update(int tabId, {bool active = null}) async {
    var args = <dynamic>[tabId];

    var updateProperties = {};

    if(active!=null) {
      updateProperties["active"] =  active;
    }

    if(updateProperties.isNotEmpty) {
      args.add(jsify(updateProperties));
    }

    final results = await _js.callMethod("update", args);

    return new Tab(results);

  }

  Future<Tab> create({String url = null, bool active = null, int windowId = null}) async {
    var args = <dynamic>[];

    var createProperties = {};

    if(active!=null) {
      createProperties["active"] =  active;
    }
    if(url!=null) {
      createProperties["url"] =  url;
    }
    if(windowId!=null) {
      createProperties["windowId"] =  windowId;
    }

    if(createProperties.isNotEmpty) {
      args.add(jsify(createProperties));
    }

    final results = await _js.callMethod("create", args);

    return new Tab(results);

  }

  Future<void> reload(int tabId, {bool bypassCache = null}) async {
    var args = <dynamic>[tabId];

    var reloadProperties = {};

    if (bypassCache != null) {
      reloadProperties["bypassCache"] = bypassCache;
    }

    if (reloadProperties.isNotEmpty) {
      args.add(jsify(reloadProperties));
    }

    await _js.callMethod("reload", args);
  }

  Future<Tab> get(int tabId) async {
    return new Tab(await _js.callMethod("reload", [tabId]));
  }
}
