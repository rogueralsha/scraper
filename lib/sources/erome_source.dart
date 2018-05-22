import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'src/simple_url_scraper.dart';

class EromeSource extends ASource {
  static final Logger _log = new Logger("EromeSource");


  static final RegExp _regExp = new RegExp(
      "https?:\\/\\/(www\\.)?erome\.com\\/a\\/([^\\/]+)\$",
      caseSensitive: false);

  EromeSource() {
    this.urlScrapers.add(new SimpleUrlScraper(this, _regExp,
        [new SimpleUrlScraperCriteria(LinkType.video, "source[label='HD']"),
        new SimpleUrlScraperCriteria(LinkType.image, "img.img-front")],
        saveByDefault: false));
  }


}
