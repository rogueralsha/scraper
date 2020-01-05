import 'dart:html';
import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';
import 'package:scraper/globals.dart';

class ThothubSource extends ASource {
  static final Logger _log = new Logger("ThothubSource");


  static final RegExp _pageRegexp = new RegExp(
      r"^https?://thothub\.tv/\d{4}/\d{2}/\d{2}/([^\/]+)/",
      caseSensitive: false);

  ThothubSource(SettingsService settings) : super(settings);

  @override
  bool canScrapePage(String url,
      {Document document, bool forEvaluation = false}) {
    _log.finest("canScrapePage");

    return _pageRegexp.hasMatch(url);
  }


  @override
  Future<bool> manualScrape(
      PageInfo pageInfo, String url, Document document) async {
    _log.finest("manualScrape");

    pageInfo.promptForDownload = true;
    pageInfo.saveByDefault = false;
    if (_pageRegexp.hasMatch(url)) {
      pageInfo.artist = _pageRegexp.firstMatch(url)[1];
    } else {
      pageInfo.artist = "Thothub";
    }

    sendPageInfo(pageInfo);

    final Element ele = document.querySelector("figure.mace-gallery-teaser");

    if(ele==null) {
      throw new Exception("Mace gallery element not found");
    }

    _log.finer(ele.dataset.keys);

    final String dataString = ele.dataset["g1Gallery"];

    _log.finer(dataString);


    if((dataString??"").trim().isEmpty) {
      throw new Exception("Mace gallery data empty");
    }

    final List data = jsonDecode(dataString);

    for(Map item in data) {
      this.createAndSendLinkInfo(item["full"], url, thumbnail: item["thumbnail"]);
    }

    return true;
  }


}
