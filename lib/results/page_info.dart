import 'dart:js';

import 'package:logging/logging.dart';

import 'serializable.dart';

export 'link_info.dart';

class PageInfo extends Serializable {
  static final Logger _log = new Logger("PageInfo");

  String sourceUrl;
  String source;
  String sourceName;
  String artist;
  String error;
  String setName;
  bool leftAlign = false;
  int tabId;

  bool saveByDefault = true;
  bool incrementalLoader = false;
  bool promptForDownload = false;

  PageInfo(this.source, this.sourceName, this.sourceUrl, this.tabId);

  PageInfo.fromJsObject(JsObject data) {
    _log.info("PageInfo.fromJson");
    this.source = data["source"];
    this.sourceName = data["sourceName"];
    this.sourceUrl = data["sourceUrl"];
    this.artist = data["artist"];
    this.error = data["error"];
    this.leftAlign = data["leftAlign"];
    this.tabId = data["tabId"];
    this.saveByDefault = data["saveByDefault"];
    this.incrementalLoader = data["incrementalLoader"];
    this.promptForDownload = data["promptForDownload"];
    this.setName = data["setName"];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> output = <String, dynamic>{};
    output["source"] = source;
    output["sourceName"] = sourceName;
    output["sourceUrl"] = sourceUrl;
    output["artist"] = artist;
    output["error"] = error;
    output["leftAlign"] = leftAlign;
    output["tabId"] = tabId;
    output["incrementalLoader"] = incrementalLoader;
    output["saveByDefault"] = saveByDefault;
    output["promptForDownload"] = promptForDownload;
    output["setName"] = setName;

    return output;
  }
}
