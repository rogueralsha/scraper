import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:angular_components/material_datepicker/range.dart';

import 'downloads/download_delta.dart';
import 'downloads/download_item.dart';
import 'enums/filename_conflict_action.dart';
import 'tools.dart';

class Downloads {
  final JsObject _js;


  final StreamController<DownloadDelta> _onChangedController = new StreamController<DownloadDelta>.broadcast();

  Stream<DownloadDelta> get onChanged => _onChangedController.stream;



  Downloads(JsObject parent): _js = parent["downloads"]
  {
    if(this._js==null)
      throw new Exception("Downloads js object is null");
    _js["onChanged"].callMethod("addListener", [this.onChangedCallback]);

  }


  void onChangedCallback(JsObject obj) {
    _onChangedController.add(new DownloadDelta(obj));
  }

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

    var result = _js.callMethod("download", [jsify(options)]);
    print(jsVarDump(result));
    return result;
  }

  Future<List<DownloadItem>> search({int id}) async {
    final query = {};

    if (id != null) {
      query["body"] = id;
    }

    var args = [];

    if(query.isNotEmpty) {
      args.add(jsify(query));
    }

    final results = await _js.callMethod("search", [args]);
    final List<DownloadItem> output = <DownloadItem>[];
    for(var item in results) {
      output.add(new DownloadItem(item));
    }
    return output;
  }

}