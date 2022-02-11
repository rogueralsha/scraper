import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class NewgroundsSource extends ASource {
  static final Logger _log = new Logger("NewgroundsSource");

  @override
  String get sourceName => "newgrounds";
  static final RegExp _artRegExp = new RegExp(
      r"^https?://(www\.)?newgrounds\.com/art/view/([^/]+)/.+",
      caseSensitive: false);
  static final RegExp _videoRegExp = new RegExp(
      r"^https?://(www\.)?newgrounds\.com/portal/view/.+",
      caseSensitive: false);

  static final RegExp _artistRegExp = new RegExp(
      r"^https?://([^.]+)\.newgrounds\.com/(art|movies)",
      caseSensitive: false);

  NewgroundsSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(this, _artistRegExp, [
        new SimpleUrlScraperCriteria(
            LinkType.page, "div.portalitem-art-icons a"),
        new SimpleUrlScraperCriteria(
            LinkType.page, "div.portalsubmission-icons a"),
      ]))
      ..add(new SimpleUrlScraper(this, _artRegExp, [
        new SimpleUrlScraperCriteria(LinkType.image, "div.image img"),
      ]))
      ..add(new SimpleUrlScraper(
          this,
          _videoRegExp,
          [
            new SimpleUrlScraperCriteria(
                LinkType.video, "div#ng-global-video-player video"),
          ]));
  }
}
