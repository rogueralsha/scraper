import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class SlusheSource extends ASource {
  static final Logger logImpl = new Logger("SlusheSource");

  @override
  String get sourceName => "slushe";

  static final RegExp _galleryRegExp = new RegExp(
      r"^https?://slushe\.com/galleries/.+",
      caseSensitive: false);

  static final RegExp _videoRegExp = new RegExp(
      r"^https?://slushe\.com/video/.+",
      caseSensitive: false);

  static final RegExp _userRegExp = new RegExp(
      r"^https?://slushe\.com/([^\/]+)$",
      caseSensitive: false);

  SlusheSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _userRegExp, [
      new SimpleUrlScraperCriteria(
          LinkType.page, "div.blog-item h3.title a")
    ]));
    this.urlScrapers.add(new SimpleUrlScraper(this, _galleryRegExp, [
      new SimpleUrlScraperCriteria(
          LinkType.image, "div.gallery-photo a.item", thumbnailSubSelector: "img")
    ], customPageInfoScraper: scrapeImagePageInfo));
    this.urlScrapers.add(new SimpleUrlScraper(this, _videoRegExp, [
      new SimpleUrlScraperCriteria(
          LinkType.video, 'a[data-plyr="download"]',
      )
    ],
        customPageInfoScraper: scrapeImagePageInfo));

  }

  Future<Null> scrapeImagePageInfo(
      PageInfo pi, Match m, String s, Document doc) async {
    final AnchorElement ele =
    document.querySelector('div.details div.about h1.username a');
    pi.artist = ele.text;

  }

}
