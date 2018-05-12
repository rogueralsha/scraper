
import 'package:logging/logging.dart';
import 'serializable.dart';

import 'link_type.dart';
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

  LinkInfo({this.url, this.sourceUrl, this.type, this.date, this.filename, this.thumbnail, this.select, this.autoDownload, this.referrer});

  LinkInfo.fromJson(Map data) {
    this.url = data["url"];
    this.type = LinkType.values[data["type"]];
    this.date = data["date"];
    this.filename = data["filename"];
    this.thumbnail = data["thumbnail"];
    this.select = data["select"];
    this.autoDownload = data["autoDownload"];
  }

  Map<String,dynamic> toJson() {
    Map<String,dynamic> output = <String,dynamic>{};
    output["url"] = url;
    output["type"] = this.type.index;
    output["date"] = date?.toIso8601String()??"";
    output["filename"] = filename;
    output["thumbnail"] = thumbnail;
    output["select"] = select;
    output["autoDownload"] = autoDownload;

    return output;
  }



}
