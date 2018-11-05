import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class EromeSource extends ASource {
  static final Logger _log = new Logger("EromeSource");

  static final RegExp _regExp = new RegExp(
      r"https?://(www\.)?erome\.com/[ai]/([^/]+)$",
      caseSensitive: false);

  static final RegExp _userRegExp =
      new RegExp(r"https?://(www\.)?erome\.com/([^/]+)$", caseSensitive: false);

  EromeSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(this, _userRegExp,
          [new SimpleUrlScraperCriteria(LinkType.page, "div#albums a")],
          customPageInfoScraper: scrapePageInfo))
      ..add(new SimpleUrlScraper(
          this,
          _regExp,
          [
            new SimpleUrlScraperCriteria(LinkType.video, "video"),
            new SimpleUrlScraperCriteria(LinkType.image, "img.img-front")
          ],
          customPageInfoScraper: scrapePageInfo));
  }

  Future<Null> scrapePageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.finest("scrapePageInfo");
    final ElementList<AnchorElement> anchorElements =
        document.querySelectorAll("div.username a");
    if (anchorElements.length >= 2) {
      AnchorElement ele = anchorElements[1];
      pageInfo
        ..saveByDefault = true
        ..artist = ele.text;
    } else {
      await this.emptyPageScraper(pageInfo, m, url, doc);
    }
  }
}
