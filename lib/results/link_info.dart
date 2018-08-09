import 'dart:js';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'link_type.dart';
import 'serializable.dart';

export 'link_type.dart';

class LinkInfo extends Serializable {
  static final Logger _log = new Logger("LinkInfo");

  String url;
  String sourceUrl;
  LinkType type;
  DateTime date;
  String filename;
  String thumbnail;
  String referrer;
  bool select;
  bool autoDownload;

  LinkInfo({this.url,
    this.sourceUrl,
    this.type,
    this.date,
    this.filename,
    this.thumbnail,
    this.select,
    this.autoDownload,
    this.referrer});

  LinkInfo.fromJson(JsObject data) {
    _log..finest("fromJson")..finest(jsVarDump(data));
    this.url = data["url"];
    this.type = LinkType.values[data["type"]];
    this.date = data["date"];
    this.filename = data["filename"];
    this.thumbnail = data["thumbnail"];
    this.select = data["select"];
    this.autoDownload = data["autoDownload"];
    this.referrer = data["referrer"];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> output = <String, dynamic>{};
    output["url"] = url;
    output["type"] = this.type.index;
    output["date"] = date?.toIso8601String() ?? "";
    output["filename"] = filename;
    output["thumbnail"] = thumbnail;
    output["select"] = select;
    output["autoDownload"] = autoDownload;
    output["referrer"] = referrer;

    return output;
  }

  bool get showThumbnail {
    if(thumbnail==null||thumbnail==url) {
      if(this.type==LinkType.image) {
        return true;
      }
      return false;
    }
    return false;
  }
}
