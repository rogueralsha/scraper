import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class CosplayEroticaSource extends ASource {
  static final Logger _log = new Logger("CosplayEroticaSource");

  @override
  String get sourceName => "cosplay_erotica";
  static final RegExp _galleryRegExp = new RegExp(
      r"^https?://(sbl09i3petn\.)?cosplayerotica\.com/content/members/index.php\?page=(.+)",
      caseSensitive: false);
  static final RegExp _downloadRegExp = new RegExp(
      r"^https?://(sbl09i3petn\.)?cosplayerotica\.com/content/members/([^/]+)/download.zip",
      caseSensitive: false);
  static final RegExp _studioDownloadRegExp = new RegExp(
      r"^https?://(sbl09i3petn\.)?cosplayerotica\.com/content/members/sc/([^/]+)/download.zip",
      caseSensitive: false);

  static final RegExp _videoRegExp = new RegExp(
      r"^https?://(sbl09i3petn\.)?cosplayerotica\.com/content/members/videos/.+",
      caseSensitive: false);


  CosplayEroticaSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(
          this,
          _galleryRegExp,
          [
            new SimpleUrlScraperCriteria(LinkType.file, "a",
                linkRegExp: _downloadRegExp),
            new SimpleUrlScraperCriteria(LinkType.file, "a",
                linkRegExp: _studioDownloadRegExp),
            new SimpleUrlScraperCriteria(LinkType.video, "a",
                linkRegExp: _videoRegExp),
            new SimpleUrlScraperCriteria(LinkType.image, "div#pic a"),
            new SimpleUrlScraperCriteria(LinkType.page, "div#bonus a",
                linkRegExp: _galleryRegExp, limit: 1),
          ],
          customPageInfoScraper: scrapePageInfo));
  }

  Future<Null> scrapePageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.finest("scrapePageInfo");

    await this.emptyPageScraper(pageInfo, m, url, doc);

    pageInfo.artist = "cosplay_erotica";
    pageInfo.setName = m.group(2);

    pageInfo.saveByDefault = false;
  }
}
