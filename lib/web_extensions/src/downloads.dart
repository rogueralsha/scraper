@JS('browser.downloads')
library downloads;


import 'dart:async';
import 'dart:html';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'package:angular_components/material_datepicker/range.dart';
import 'package:logging/logging.dart';

import 'downloads/download_delta.dart';
import 'downloads/download_item.dart';
import 'enums/filename_conflict_action.dart';
import 'tools.dart';

@JS()
class Downloads {
  static final Logger _log = new Logger("Downloads");

  final StreamController<DownloadDelta> _onChangedController = new StreamController<DownloadDelta>.broadcast();

  Stream<DownloadDelta> get onChanged => _onChangedController.stream;

//  Downloads(JsObject parent): _js = parent["downloads"]
//  {
//    if(this._js==null)
//      throw new Exception("Downloads js object is null");
//    _js["onChanged"].callMethod("addListener", [this.onChangedCallback]);
//
//  }


//  void onChangedCallback(JsObject obj) {
//    _onChangedController.add(new DownloadDelta(obj));
//  }

  Future<int> download({
    String body,
    FilenameConflictAction conflictAction,
    String filename,
    Map headers,
    bool incognito,
    String method,
    bool saveAs,
    String url,
  })  async {
    final options = {};

    if (body != null) {
      options["body"] = body;
    }
    if (filename != null) {
      options["filename"] = filename;
    }
    if (incognito != null) {
      options["incognito"] = incognito;
    }
    if (method != null) {
      options["method"] = method;
    }
    if (saveAs != null) {
      options["saveAs"] = saveAs;
    }
    if (url != null) {
      options["url"] = url;
    }

    if (conflictAction != null) {
      switch(conflictAction) {
        case FilenameConflictAction.overwrite:
          options["conflictAction"] = "overwrite";
          break;
        case FilenameConflictAction.prompt:
          options["conflictAction"] = "prompt";
          break;
        case FilenameConflictAction.uniquify:
          options["conflictAction"] = "uniquify";
          break;
      }
    }
//    if (headers != null && headers.isNotEmpty) {
//      options["headers"] = [];
//        for(var key in headers.keys) {
//          options["headers"].add({"name": key, "value" : headers[key]});
//        }
//    }

    final result = await promiseToFuture(_download(options));
    _log.finest(result);
    return result;
  }


  @JS("download")
  external dynamic _download(Map options);

  Future<List<DownloadItem>> search({int id}) async {
    final query = {};

    if (id != null) {
      query["body"] = id;
    }

    final results = await promiseToFuture(_search(query));
    final List<DownloadItem> output = <DownloadItem>[];
    for(var item in results) {
      output.add(new DownloadItem(item));
    }
    return output;
  }

  @JS("search")
  external dynamic _search(Map query);

}