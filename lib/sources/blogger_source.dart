import 'dart:async';
import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'src/simple_url_scraper.dart';

class BloggerSource extends ASource {
  static final Logger logImpl = new Logger("BloggerSource");

  static final RegExp _regExp = new RegExp(
      "https?://([^\\.]+)\\.blogspot\\.com/.*",
      caseSensitive: false);

  static final RegExp _postRegExp = new RegExp(
      "https?://([^\\.]+)\\.blogspot\\.com/\\d{4}\\/\\d{2}\\/.*",
      caseSensitive: false);

  BloggerSource() {
    this.urlScrapers.add(new SimpleUrlScraper(this, _postRegExp,
        [new SimpleUrlScraperCriteria(LinkType.image, "div.post-body a")]));

    this.urlScrapers.add(new SimpleUrlScraper(
          this,
          _regExp,
          [
            new SimpleUrlScraperCriteria(LinkType.page, "a.timestamp-link"),
            new SimpleUrlScraperCriteria(
                LinkType.page, "div.blog-pager a.blog-pager-older-link",
                limit: 1)
          ],
        ));
  }
}