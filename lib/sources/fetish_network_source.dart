import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class FetishNetworkSource extends ASource {
  static final Logger _log = new Logger("FetishNetworkSource");

  @override
  String get sourceName => "fetish_network";


  static final RegExp _regExp = new RegExp(
      r"^https?://(www\.)?fetishnetwork\.com/members/showgal.php\?g=content/shared/photo_archives/[^/]+/([^/]+)/.+$",
      caseSensitive: false);

  static final RegExp _imageRegExp = new RegExp(
      r"^https?://(www\.)?fetishnetwork\.com/members/view.php\?i=([^&]+)&.+$",
      caseSensitive: false);



  FetishNetworkSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(
          this,
          _regExp,
          [
            new SimpleUrlScraperCriteria(LinkType.image, "div.mosaicflow__item a",
                validateLinkInfo: validatePaginationLinkElement,
                linkRegExp: _imageRegExp),
          ], urlRegexGroup: 2)
      );
  }

  bool validatePaginationLinkElement(LinkInfo li, Element e) {
    if(!_imageRegExp.hasMatch(li.url)) {
      return false;
    }
    final Match m = _imageRegExp.firstMatch(li.url);
    li.url = "http://fetishnetwork.com/members/" + m.group(2);
    return true;
  }


}
