import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class GelbooruSource extends ASource {
  static final Logger logImpl = new Logger("GelbooruSource");

  @override
  String get sourceName => "gelbooru";

  static final RegExp _galleryRegexp = new RegExp(
      r"^https?://gelbooru\.com/index\.php\?page=post&s=list.+",
      caseSensitive: false);
  static final RegExp _viewRegexp = new RegExp(
      r"^https?://gelbooru\.com/index\.php\?page=post&s=view",
      caseSensitive: false);

  GelbooruSource(SettingsService settings) : super(settings) {
    this
      ..urlScrapers.add(new SimpleUrlScraper(
          this,
          _viewRegexp,
          [
            new SimpleUrlScraperCriteria(LinkType.image, "ul#tag-list a",
                validateLinkInfo: (LinkInfo li, Element ele) =>
                    ele.text?.toLowerCase() == "original image")
          ],
          customPageInfoScraper: scrapeSubredditPageInfo))
      ..urlScrapers.add(new SimpleUrlScraper(this, _galleryRegexp, [
        new SimpleUrlScraperCriteria(
            LinkType.page, "div.thumbnail-container a"),
        new SimpleUrlScraperCriteria(LinkType.page, "p.pagination a",
            validateLinkInfo: (LinkInfo li, Element ele) =>
                ele.text == "Next »")
      ]));
  }

  Future<Null> scrapeSubredditPageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    logImpl.finest("scrapeSubredditPageInfo");

    final List<AnchorElement> anchors =
        doc.querySelectorAll("li.tag-type-artist a");

    if (anchors.length >= 2) {
      pageInfo.artist = anchors[1].text;
    }
  }
}
