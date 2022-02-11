import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class FamousInternetGirlsSource extends ASource {
  static final Logger _log = new Logger("FamousInternetGirlsSource");

  @override
  String get sourceName => "famouseinternetgirls";

  static final RegExp _regExp = new RegExp(
      r"^https?://onlyfansforum\.?famousinternetgirls\.com/threads/([^/]+)/.*$",
      caseSensitive: false);

  FamousInternetGirlsSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(
          this,
          _regExp,
          [
            new SimpleUrlScraperCriteria(LinkType.image, ".message-userContent div.bbImageWrapper img", contentDispositionFileName: true),
            new SimpleUrlScraperCriteria(LinkType.image, "section.message-attachments li.file a", contentDispositionFileName: true,
                thumbnailSubSelector: "img"),
            new SimpleUrlScraperCriteria(LinkType.image, "div.message-content img.bbImage", contentDispositionFileName: false,
                linkAttribute: "data-url"),
            new SimpleUrlScraperCriteria(LinkType.video, "div.message-content div.bbMediaWrapper video"),
          ],urlRegexGroup: 1));
  }
}
