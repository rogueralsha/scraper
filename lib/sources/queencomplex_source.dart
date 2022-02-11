import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class QueencomplexSource extends ASource {
  static final Logger logImpl = new Logger("QueencomplexSource");

  @override
  String get sourceName => "queencomplex";

  static final RegExp _regExp = new RegExp(
      r"^https?://queencomplex\.net/qumem/([^/]+)/",
      caseSensitive: false);

  QueencomplexSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _regExp, [
      new SimpleUrlScraperCriteria(
          LinkType.image, "a.fg-thumb"),
      new SimpleUrlScraperCriteria(
          LinkType.video, "video.avia_video")
    ], customPageInfoScraper: scrapeImagePageInfo));

  }

  Future<Null> scrapeImagePageInfo(
      PageInfo pi, Match m, String s, Document doc) async {
    pi.artist = "queencomplex";
    pi.setName = m[1];
  }
}
