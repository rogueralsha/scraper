import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class Rule34XXXSource extends ASource {
  static final Logger logImpl = new Logger("Rule34XXXSource");

  @override
  String get sourceName => "rule34xxx";

  static final RegExp _galleryRegexp = new RegExp(
      r"^https?://rule34\.xxx/index.php\?page=post&s=list&tags=([^&]+).*",
      caseSensitive: false);
  static final RegExp _viewRegexp = new RegExp(
      r"^https?://rule34\.xxx/index.php\?page=post&s=view&id=\d+.*",
      caseSensitive: false);

  Rule34XXXSource(SettingsService settings) : super(settings) {
    this
      ..urlScrapers.add(new SimpleUrlScraper(this, _galleryRegexp,
          [new SimpleUrlScraperCriteria(LinkType.page, "div.content span.thumb a, div#paginator div.pagination a[alt='next']")]))
      ..urlScrapers.add(new SimpleUrlScraper(this, _viewRegexp,
          [new SimpleUrlScraperCriteria(LinkType.file, "meta[property='og:image']")]))
        ;
  }

}
