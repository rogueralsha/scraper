import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class SuicideGirlsSource extends ASource {
  static final Logger logImpl = new Logger("SuicideGirlsSource");

  @override
  String get sourceName => "suicide_girls";


  static final RegExp _galleryRegExp = new RegExp(
      r"^https?://(www\.)?suicidegirls\.com/girls/([^/]+)/album/.+",
      caseSensitive: false);

  SuicideGirlsSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(this, _galleryRegExp, [
        new SimpleUrlScraperCriteria(LinkType.image, "div.album-container li.photo-container a"),

      ], setNameSelector: "div.content-box header.header h2.title"))
    ;
  }
}
