import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class DartlerySource extends ASource {
  static final Logger _log = new Logger("DartlerySource");
  static final RegExp _SearchRegExp = new RegExp(
      r"^https?://gallery\.darkholme\.net/#/items/.+",
      caseSensitive: false);

  static final RegExp _itemRegexp = new RegExp("^https?://gallery\.darkholme\.net/#/item/([0-9a-f]{64})", caseSensitive: false);

  DartlerySource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _SearchRegExp,
        [new SimpleUrlScraperCriteria(LinkType.file, "div.item a",  validateLinkInfo: validateLinkElement, linkRegExp: _itemRegexp)]));
  }

  bool validateLinkElement(LinkInfo li, Element e) {
    _log.finest("validateLinkElement");

    final String id = _itemRegexp.firstMatch(li.url).group(1);
    li.thumbnail = "https://gallery.darkholme.net/data/thumbnails/${id.substring(0,2)}/$id";
    li.url = "https://gallery.darkholme.net/data/original/${id.substring(0,2)}/$id";

    return true;
  }

}
