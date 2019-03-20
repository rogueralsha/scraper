import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';
import 'package:scraper/globals.dart';

class ThothubSource extends ASource {
  static final Logger _log = new Logger("ThothubSource");


  static final RegExp _albumRegexp = new RegExp(
      r"^https?://thothub\.tv/gmedia-album/([^/]+)/",
      caseSensitive: false);

  ThothubSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _albumRegexp,
        [new SimpleUrlScraperCriteria(LinkType.image, "a.gmPhantom_Thumb")]));
  }



}
