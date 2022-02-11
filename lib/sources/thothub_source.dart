import 'dart:html';
import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';
import 'package:scraper/globals.dart';

class ThothubSource extends ASource {
  static final Logger _log = new Logger("ThothubSource");

  @override
  String get sourceName => "thothub";

  static final RegExp _pageRegexp = new RegExp(
      r"^https?://thothub\.tv/\d{4}/\d{2}/\d{2}/([^\/]+)/",
      caseSensitive: false);

  static final RegExp _albumRegexp = new RegExp(
      r"^https?://thothub\.tv/gmedia-album/([^/]+)/",
      caseSensitive: false);

  ThothubSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _albumRegexp,
        [new SimpleUrlScraperCriteria(LinkType.image, "a.gmPhantom_Thumb")]));
  }

  @override
  bool canScrapePage(String url,
      {Document document, bool forEvaluation = false}) {
    _log.finest("canScrapePage");

    return _pageRegexp.hasMatch(url) || _albumRegexp.hasMatch(url);
  }


  @override
  Future<bool> manualScrape(
      PageInfo pageInfo, String url, Document document) async {
    _log.finest("manualScrape");

    //pageInfo.promptForDownload = true;
    pageInfo.saveByDefault = false;
    if (_pageRegexp.hasMatch(url)) {
      pageInfo.artist = _pageRegexp.firstMatch(url)[1];
    } else {
      pageInfo.artist = "Thothub";
    }

    sendPageInfo(pageInfo);

    final List<Element> videoEles = document.querySelectorAll("video");
    for(var ele in videoEles) {
      final link = this.createLinkFromElement(ele, url);
      this.sendLinkInfo(link);
    }


    final Element ele = document.querySelector("figure.mace-gallery-teaser");

    if(ele!=null) {

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
    }

    return true;
  }


}
