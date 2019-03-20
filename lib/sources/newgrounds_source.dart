import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class NewgroundsSource extends ASource {
  static final Logger _log = new Logger("NewgroundsSource");

  //https://www.newgrounds.com/art/view/feguimel/yuuko


  static final RegExp _artViewRegexp = new RegExp(
      r"^https?://.+\.newgrounds\.com/art/view/([^/]+)/[^/]+/?",
      caseSensitive: false);

  NewgroundsSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _artViewRegexp,
        [new SimpleUrlScraperCriteria(LinkType.image, "a.medium_image")]));
  }

}
