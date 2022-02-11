import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class RinCitySource extends ASource {
  static final Logger logImpl = new Logger("RinCitySource");

  @override
  String get sourceName => "rin_city";

  static final RegExp _regExp = new RegExp(
      r"^https?://rin-city\.com/gallery/.+",
      caseSensitive: false);

  static final RegExp _galleryRegExp = new RegExp(
      r"^https?://rin-city\.com/gallery[^/]*",
      caseSensitive: false);

  RinCitySource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _regExp, [
      new SimpleUrlScraperCriteria(
          LinkType.image, "div.mygallery-container figure div", linkAttribute: "href")
    ]));
    this.urlScrapers.add(new SimpleUrlScraper(this, _galleryRegExp, [
      new SimpleUrlScraperCriteria(
          LinkType.page, "div.tag-category div.items-row a",)
    ]));

  }

}
