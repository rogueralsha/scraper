import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class FandomSource extends ASource {
  static final Logger logImpl = new Logger("FandomSource");

  @override
  String get sourceName => "fandom";

  static final RegExp _galleryRegexp = new RegExp(
      r"^https?://(.+)\.fandom\.com/wiki/([^/]+)(/.*)?",
      caseSensitive: false);

  static final RegExp _thumbnailRegexp = new RegExp(
      r"^(https?://static\.wikia\.nocookie\.net/.+/([^/]+))/revision/.+",
      caseSensitive: false);

  FandomSource(SettingsService settings) : super(settings) {
    //
    this
      .urlScrapers.add(new SimpleUrlScraper(this, _galleryRegexp,
          [
            new SimpleUrlScraperCriteria(LinkType.image, "div#content figure > a", validateLinkInfo: validateGalleryPopupLink),
            new SimpleUrlScraperCriteria(LinkType.image, "div.wikia-gallery-item a img, div.mw-parser-output p a.image img",
                validateLinkInfo: validateGalleryPopupLink
            ),
          ], urlRegexGroup: 2))
        ;
  }

  bool validateGalleryPopupLink(LinkInfo li, Element e) {
    logImpl.finest("validateGalleryPopupLink($li, $e)");
    if(e is ImageElement && e!=null&&e.dataset.containsKey("src")) {
      final ImageElement imgEle = e;
      final String dataSrc = imgEle.dataset["src"];
      li.url = dataSrc;
      li.thumbnail = imgEle.src;
    }

    if(_thumbnailRegexp.hasMatch(li.url)) {
      final Match m = _thumbnailRegexp.firstMatch(li.url);
      li.url = m.group(1);
      li.filename = m.group(2).replaceAll("~", "_");
    }

    return true;
  }

}
