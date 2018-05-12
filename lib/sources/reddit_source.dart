import 'dart:async';
import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'src/url_scraper.dart';

class RedditSource extends ASource {
  static final Logger _log = new Logger("RedditSource");
  static final RegExp _regExp = new RegExp("https?://www\\.reddit\\.com/r/([^\\/]+)\\/.*", caseSensitive: false);
  static final RegExp _postRegexp = new RegExp("https?://www\\.reddit\\.com/r/([^\\/]+)/comments/.*", caseSensitive: false);
  static final RegExp _imageRegexp = new RegExp("https?://i\\.redd\\.it/.*",caseSensitive: false);

  RedditSource() {
   this.urlScrapers.add(new UrlScraper(_regExp, scrapeSubredditPageInfo, scrapeSubredditPageLinks));
    this.urlScrapers.add(new UrlScraper(_imageRegexp, emptyPageScraper, selfLinkScraper));
  }

  bool determineIfDirectFileLink(String url) => _imageRegexp.hasMatch(url);

  Future<Null> scrapeSubredditPageInfo (PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.finest("scrapeSubredditPageInfo");
    pageInfo.saveByDefault = false;
    pageInfo.artist = m.group(1);
  }
  Future<Null> scrapeSubredditPageLinks(String url, Document doc) async {
    _log.finest("scrapeSubredditPageLinks");
    ElementList links = document.querySelectorAll("a.title");
    for (AnchorElement linkElement in links) {
        String link = linkElement.href;

        _log.info("Found URL: " + link);
        if (_postRegexp.hasMatch(link)) {
          //continue;
        } else {
          evaluateLink(url, link);
        }
    }

    links = document.querySelectorAll("div.commentarea  div[data-type=comment] div.usertext-body a");
    for (AnchorElement linkElement in links) {
      String link = linkElement.href;
      _log.info("Found URL: " + link);
      if (_postRegexp.hasMatch(link)) {
        //continue;
      } else {
        evaluateLink(url, link, select: false);
      }


    }

  }

//  imageRegexp: new RegExp("https?://i\\.redd\\.it/.*", 'i'),

}