import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class CyberDropSource extends ASource {
  static final Logger _log = new Logger("CyberDropSource");

  @override
  String get sourceName => "cyberdrop";
  static final RegExp _regExp = new RegExp(
      r"^https?://(www\.)?cyberdrop\.me/a/.+",
      caseSensitive: false);

  CyberDropSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(
          this,
          _regExp,
          [
            new SimpleUrlScraperCriteria(LinkType.image, "a.image")
          ],
          customPageInfoScraper: scrapePageInfo));
  }

  Future<Null> scrapePageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.finest("scrapePageInfo");

    await this.emptyPageScraper(pageInfo, m, url, doc);

    final Element title = document.querySelector("h1#title");
    if(title!=null) {
      pageInfo.setName = title.text;
    }

    pageInfo.saveByDefault = false;
  }
}
