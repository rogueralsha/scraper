@JS('browser.tabs')
library tabs;

import 'dart:async';
import 'dart:html';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:logging/logging.dart';

import 'package:scraper/globals.dart';

import 'tools.dart';
import 'tab.dart';
import 'port.dart';

@JS()
class Tabs {
  static final Logger _log = new Logger("Tabs");

//  Tabs(JsObject parent): _js = parent["tabs"] {
//    if(this._js==null)
//      throw new Exception("Tabs js object is null");
//  }

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

    //final output = <Tab>[];
    var results =  await promiseToFuture<List<Tab>>(_query(args));
    return results;
//
//    for(var result in results) {
//      output.add(new Tab(result));
//    }
//
//    return output;
  }

  @JS("query")
  external dynamic _query(Map queryInfo);

  Future<dynamic> sendMessage(int tabId, dynamic message, {int frameId = null}) async {
    var options= {};

    if(frameId!=null) {
      options["frameId"] = frameId;
    }

    dynamic results;
    if(options.isNotEmpty) {
       results = await promiseToFuture(_sendMessageOptions(tabId, message, options));
    } else {
      results = await promiseToFuture(_sendMessage(tabId, message));
    }

    return results;
  }

  @JS("sendMessage")
  external dynamic _sendMessageOptions(int tabId, dynamic message, Map options);
  @JS("sendMessage")
  external dynamic _sendMessage(int tabId, dynamic message);

  Future<void> remove(int tabId) async {
    await promiseToFuture(_remove(tabId));
  }

  @JS("remove")
  external dynamic _remove(int tabId);


  Port connect(int tabId, {String name = null, int frameId = null}) {
    var connectInfo = {};

    if(name!=null) {
      connectInfo["name"] =  name;
    }
    if(frameId!=null) {
      connectInfo["frameId"] =  frameId;
    }

    dynamic results;
    if(connectInfo.isNotEmpty) {
      results = _connectInfo(tabId,connectInfo);
    } else {
      results = _connect(tabId);
    }

    return results;
  }

  @JS("connect")
  external Port _connectInfo(int tabId, Map connectInfo);
  @JS("connect")
  external Port _connect(int tabId);

  Future<Tab> update(int tabId, {bool active = null}) async {
    var updateProperties = {};

    if(active!=null) {
      updateProperties["active"] =  active;
    }

    final results = await promiseToFuture(_update(tabId, updateProperties));

    return new Tab(results);
  }

  @JS("update")
  external dynamic _update(int tabId, Map updateProperties);

  Future<Tab> create({String url = null, bool active = null, int windowId = null}) async {
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

    final results = await promiseToFuture(_create(createProperties));

    return new Tab(results);

  }

  @JS("create")
  external dynamic _create(Map createProperties);


  Future<void> reload(int tabId, {bool bypassCache = null}) async {
    var reloadProperties = {};

    if (bypassCache != null) {
      reloadProperties["bypassCache"] = bypassCache;
    }

    await promiseToFuture(_reload(tabId, reloadProperties));
  }
  @JS("reload")
  external dynamic _reload(int tabId, Map reloadProperties);

  Future<Tab> get(int tabId) async {
    final results = await promiseToFuture(_get(tabId));

    return new Tab(results);

  }

  @JS("get")
  external dynamic _get(int tabId);

}


