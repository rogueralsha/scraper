import 'dart:js';
import 'package:logging/logging.dart';
import 'serializable.dart';
export 'link_info.dart';

class PageInfo extends Serializable {
  static final Logger _log = new Logger("PageInfo");

  String artist;
  String error;
  int tabId;

  bool saveByDefault = true;
  bool incrementalLoader = false;

  PageInfo(this.tabId);

  PageInfo.fromJsObject(JsObject data) {
    _log.info("PageInfo.fromJson");
    this.artist = data["artist"];
    this.error = data["error"];
    this.tabId = data["tabId"];
    this.saveByDefault = data["saveByDefault"];
    this.incrementalLoader = data["incrementalLoader"];
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> output = <String, dynamic>{};
    output["artist"] = artist;
    output["error"] = error;
    output["tabId"] = tabId;
    output["incrementalLoader"] = incrementalLoader;
    output["saveByDefault"] = saveByDefault;

    return output;
  }
}
