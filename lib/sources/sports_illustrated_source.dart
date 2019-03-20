import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';
import 'package:scraper/globals.dart';

class SportsIllustratedSource extends ASource {
  static final Logger _log = new Logger("SportsIllustratedSource");


  static final RegExp _photosViewRegexp = new RegExp(
      r"^https?://.+\.si\.com/swimsuit/model/([^/]+)/\d+/.+",
      caseSensitive: false);

  static final RegExp _swimDailyViewRegexp = new RegExp(
      r"^https?://.+\.si\.com/swim-daily/photos/\d+/\d+/\d+/([^/]+)",
      caseSensitive: false);

  static final RegExp _imageHostRegExp = new RegExp(
      r"^https?://imagesvc\.timeincapp\.com/v3/mm/image\?url=([^&]+)&.+",
      caseSensitive: false);

  SportsIllustratedSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _photosViewRegexp,
        [new SimpleUrlScraperCriteria(LinkType.image, "div.vertical-slide div.lazy-image",
            linkAttribute: "data-src",
            validateLinkInfo: (LinkInfo li, Element e) {
          if (_imageHostRegExp.hasMatch(li.url)) {
            final String url = _imageHostRegExp.firstMatch(li.url)[1];
            li.url = url;
            li.filename = getFileNameFromUrl(url);
          }

          return true;
        } )]));
    this.urlScrapers.add(new SimpleUrlScraper(this, _swimDailyViewRegexp, [
      new SimpleUrlScraperCriteria(LinkType.image, "div.gallery div.media-img div.lazy-image", linkAttribute: "data-src")

    ]));
  }



}
