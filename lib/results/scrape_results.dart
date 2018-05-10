import 'dart:js';
import 'package:logging/logging.dart';
import 'scrape_result.dart';
import 'serializable.dart';
export 'scrape_result.dart';


class ScrapeResults extends Serializable {
  final _log = new Logger("DeviantArtSource");

  bool matchFound = false;
  String artist;
  String error;
  int tabId;
  List<ScrapeResult> results = <ScrapeResult>[];

  bool saveByDefault = true;

  static final RegExp _urlMatcherRegex = new RegExp("^https?:\\/\\/(.+)\$", caseSensitive: false);

  ScrapeResults(this.tabId);

  ScrapeResults.fromJsObject(JsObject data) {
    _log.info("ScrapeResults.fromJson");
    _log.info(data);
    this.artist = data["artist"];
    this.error = data["error"];
    this.tabId = data["tabId"];
    _log.info("Artist: ${this.artist}");
    _log.info("error: ${this.error}");
    List<Map> resultsMap = data["results"];
    if(resultsMap==null) {
      _log.warning("Null resultsMap");
    } else {
      this.results =
          resultsMap.map((Map result) => new ScrapeResult.fromJson(result));
    }
  }

  Map<String,dynamic> toJson() {
    Map<String,dynamic> output = <String,dynamic>{};
    output["artist"] = artist;
    output["error"] = error;
    output["tabId"] = tabId;
    List resultsList = [];
    for(ScrapeResult r in results) {
      resultsList.add(r.toJson());
    }
    output["results"] = resultsList;

    return output;
  }

  void addResult(ScrapeResult result) {
    String matchedLink = _urlMatcherRegex.firstMatch(result.url).group(1);
    for (int i = 0; i < this.results.length; i++) {
      String matchedOtherLink = _urlMatcherRegex.firstMatch(this.results[i].url).group(1);

      if (matchedLink == matchedOtherLink) {
        _log.info("Duplicate URL, skipping");
        return;
      }
    }
    this.results.add(result);
  }

}