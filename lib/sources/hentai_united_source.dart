import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class HentaiUnitedSource extends ASource {
  static final Logger logImpl = new Logger("HentaiUnitedSource");

  @override
  String get sourceName => "hentai_united";

  static final RegExp _profileRegExp = new RegExp(
      r"^https?://hentaiunited\.com/members/profile/([^/]+)",
      caseSensitive: false);

  static final RegExp _regExp = new RegExp(
      r"^https?://hentaiunited\.com/members/play/([^]+)/.+",
      caseSensitive: false);

  HentaiUnitedSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _regExp, [
      new SimpleUrlScraperCriteria(
          LinkType.image, "vidplayer a")
    ]));
    this.urlScrapers.add(new SimpleUrlScraper(this, _profileRegExp, [
      new SimpleUrlScraperCriteria(
          LinkType.page, "div.tab-cont ul li a")
    ]));



  }

}
