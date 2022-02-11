import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class DanbooruSource extends ASource {
  static final Logger _log = new Logger("DanbooruSource");

  @override
  String get sourceName => "danbooru";

  static final RegExp _regExp = new RegExp(
      r"^https?://(danbooru\.donmai\.us)/posts(\?.+)?$",
      caseSensitive: false);

  static final RegExp _postRegExp = new RegExp(
      r"^https?://(danbooru\.donmai\.us)/posts/\d+(\?.+)?$",
      caseSensitive: false);

  DanbooruSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(
          this,
          _regExp,
          [
            new SimpleUrlScraperCriteria(LinkType.page, "div#posts article a"),
            new SimpleUrlScraperCriteria(LinkType.page, "a.paginator-next"),
          ],urlRegexGroup: 1))
    ..add(new SimpleUrlScraper(
    this,
        _postRegExp,
    [
    new SimpleUrlScraperCriteria(LinkType.file, "li#post-option-download a"),
    ],urlRegexGroup: 1));
  }
}

