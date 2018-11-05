import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class ImageFapSource extends ASource {
  static final Logger logImpl = new Logger("ImageFapSource");
  static final RegExp _galleryRegExp = new RegExp(
      r"https?://(www\.)?imagefap\.com/pictures/\d+/.*",
      caseSensitive: false);

  static final RegExp _photoRegExp = new RegExp(
      r"https?://(www\.)?imagefap\.com/photo/\d+/.*",
      caseSensitive: false);

  ImageFapSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(this, _galleryRegExp, [
        new SimpleUrlScraperCriteria(LinkType.page, "form table a"),
        new SimpleUrlScraperCriteria(LinkType.page, "a.link3", limit: 1,
            validateLinkInfo: (LinkInfo li, Element e) {
          if (e is AnchorElement) {
            if (e.text == ":: next ::") return true;
          }
          return false;
        })
      ]))
      ..add(new SimpleUrlScraper(this, _photoRegExp, [
        new SimpleUrlScraperCriteria(LinkType.image, "div.image-wrapper img",
            limit: 1)
      ]));
  }
}
