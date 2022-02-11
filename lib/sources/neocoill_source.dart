import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class NeoCoillSource extends ASource {
  static final Logger _log = new Logger("NeoCoillSource");

  @override
  String get sourceName => "neocoill";

  static final RegExp _regExp = new RegExp(
      r"^https?://(www\.)?neocoill\.com/(illustrations|illustrations/fanart|illustrations/original|comics)/([^/]+)/?$",
      caseSensitive: false);

  NeoCoillSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(
          this,
          _regExp,
          [
            new SimpleUrlScraperCriteria(LinkType.image, "a.av-masonry-entry"),
            new SimpleUrlScraperCriteria(LinkType.image, "img.avia_image"),
            new SimpleUrlScraperCriteria(LinkType.image, "dl.gallery-item a img",
                linkAttribute: "data-orig-file"),
            new SimpleUrlScraperCriteria(LinkType.image, "div.entry-content p img",
                linkAttribute: "data-orig-file"),
          ],
                    customPageInfoScraper: scrapePageInfo));
  }

  Future<Null> scrapePageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.finest("scrapePageInfo");
    pageInfo.artist = "neocoill";
    pageInfo.setName = m.group(3);
  }
}
