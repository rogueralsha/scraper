
import 'package:logging/logging.dart';
import 'serializable.dart';

enum ResultTypes { image, page }

class ScrapeResult extends Serializable {
  static final _log = new Logger("ScrapeResult");

  String url;
  ResultTypes type;
  DateTime date;
  String filename;
  String thumbnail;
  String referrer;
  bool select;
  bool autoDownload;

  ScrapeResult({this.url, this.type, this.date, this.filename, this.thumbnail, this.select, this.autoDownload, this.referrer});

  ScrapeResult.fromJson(Map data) {
    this.url = data["url"];
    this.type = ResultTypes.values[data["type"]];
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
