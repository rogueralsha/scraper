import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class LivedoorSource extends ASource {
  static final Logger _log = new Logger("LivedoorSource");

  @override
  String get sourceName => "livedoor";

  static final RegExp _regExp = new RegExp(
      r"^https?://blog\.livedoor\.jp/([^/]+)/archives/.+$",
      caseSensitive: false);

  static final RegExp _imgRegExp = new RegExp(
      r"^https?://livedoor\.blogimg\.jp/[^/]+/imgs/.+$",
      caseSensitive: false);

  LivedoorSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(this, _regExp,
          [new SimpleUrlScraperCriteria(LinkType.image, "div.articleInner div.contentBody a", linkRegExp: _imgRegExp )]
    ));
  }

}
