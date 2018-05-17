import 'dart:async';
import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'src/url_scraper.dart';

class RedditSource extends ASource {
  static final Logger _log = new Logger("RedditSource");
  static final RegExp _regExp = new RegExp(
      "https?://www\\.reddit\\.com/r/([^\\/]+)\\/.*",
      caseSensitive: false);
  static final RegExp _postRegexp = new RegExp(
      "https?://www\\.reddit\\.com/r/([^\\/]+)/comments/.*",
      caseSensitive: false);
  static final RegExp _imageRegexp = new RegExp(
      "https?://i\\.(redd\\.it|redditmedia\\.com)/.*",
      caseSensitive: false);

  RedditSource() {
    this.directLinkRegexps.add(_imageRegexp);

    this.urlScrapers.add(new UrlScraper(
        _regExp, scrapeSubredditPageInfo, scrapeSubredditPageLinks));
    this
        .urlScrapers
        .add(new UrlScraper(_imageRegexp, emptyPageScraper, selfLinkScraper));
  }

  Future<Null> scrapeSubredditPageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.finest("scrapeSubredditPageInfo");
    pageInfo.saveByDefault = false;
    pageInfo.artist = m.group(1);
  }

  Future<Null> scrapeSubredditPageLinks(String url, Document doc) async {
    _log.finest("scrapeSubredditPageLinks");
    ElementList<AnchorElement> links = document.querySelectorAll("a.title");
    for (AnchorElement linkElement in links) {
      final String link = linkElement.href;

      if (_postRegexp.hasMatch(link)) {
        //continue;
      } else {
        evaluateLink(url, link);
      }
    }

    links = document.querySelectorAll(
        "div.commentarea  div[data-type=comment] div.usertext-body a");
    for (AnchorElement linkElement in links) {
      final String link = linkElement.href;
      if (_postRegexp.hasMatch(link)) {
        //continue;
      } else {
        evaluateLink(url, link, select: false);
      }
    }

    final ElementList<VideoElement> videoLinks = document.querySelectorAll(
        "div.reddit-video-player-root video");
    for (VideoElement videoElement in videoLinks ) {
      sendLinkInfo(createLinkFromElement(videoElement, url));
    }

  }

//  imageRegexp: new RegExp("https?://i\\.redd\\.it/.*", 'i'),

}
