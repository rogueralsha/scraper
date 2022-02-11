import 'dart:js';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'package:uuid/uuid.dart';

import 'link_type.dart';
import 'serializable.dart';

export 'link_type.dart';

class LinkInfo extends Serializable {
  static final Logger _log = new Logger("LinkInfo");

  String sourceName;
  String url;
  String sourceUrl;
  LinkType type;
  DateTime date;
  int delay;
  String filename;
  String thumbnail;
  String referer;
  String pathSuffix;
  String uuid;
  bool select;
  bool autoDownload;

  LinkInfo(this.sourceName,
      {this.url,
      this.sourceUrl,
      this.type,
      this.date,
      this.filename,
      this.thumbnail,
      this.select,
      this.autoDownload,
      this.referer,
      this.pathSuffix,
      this.delay}) {
    this.uuid = Uuid().v1();
  }

  LinkInfo.fromJson(JsObject data) {
    _log..finest("fromJson")..finest(jsVarDump(data));
    this.sourceName = data["sourceName"];
    this.url = data["url"];
    this.sourceUrl = data["sourceUrl"];
    this.type = LinkType.values[data["type"]];
    this.date = data["date"];
    this.filename = data["filename"];
    this.thumbnail = data["thumbnail"];
    this.select = data["select"];
    this.autoDownload = data["autoDownload"];
    this.referer = data["referer"];
    this.pathSuffix = data["pathSuffix"];
    this.delay = data["delay"];
    this.uuid = data["uuid"];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> output = <String, dynamic>{};
    output["sourceName"] = sourceName;
    output["url"] = url;
    output["sourceUrl"] = sourceUrl;
    output["type"] = this.type.index;
    output["date"] = date?.toIso8601String() ?? "";
    output["filename"] = filename;
    output["thumbnail"] = thumbnail;
    output["select"] = select;
    output["autoDownload"] = autoDownload;
    output["referer"] = referer;
    output["pathSuffix"] = pathSuffix;
    output["delay"] = delay;
    output["uuid"] = uuid;

    return output;
  }

  bool get showThumbnail {
    if (thumbnail == null || thumbnail == url) {
      if (this.type == LinkType.image) {
        return true;
      }
      return false;
    }
    return false;
  }
}
