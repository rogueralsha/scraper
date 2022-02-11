import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class ArielRebelSource extends ASource {
  static final Logger logImpl = new Logger("ArielRebelSource");

  @override
  String get sourceName => "ariel_rebel";

  static final RegExp _galleryRegExp = new RegExp(
      r"^https?://members\.arielrebel\.com/content_\.php\?show=galleries&gallery=(\d+)&section=\d+",
      caseSensitive: false);

  ArielRebelSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _galleryRegExp, [
      new SimpleUrlScraperCriteria(
          LinkType.image, "div.latesitemssectionpictorial a",
      )
    ],
        customPageInfoScraper: scrapePageInfo));

  }
  Future<Null> scrapePageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    await this.emptyPageScraper(pageInfo, m, url, doc);
    pageInfo.artist = "ariel_rebel";
    final Element title = document.querySelector("ol.breadcrumb li.active");
    final Match urlMatch = _galleryRegExp.firstMatch(url);
    if(title!=null) {
      pageInfo.setName = title.text;
    }
    if(pageInfo.setName?.isEmpty??true) {
      pageInfo.setName = urlMatch.group(1);
    }
  }
}
