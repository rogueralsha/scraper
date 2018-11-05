import 'dart:async';
import 'dart:html';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:html_unescape/html_unescape.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as html;
import 'a_source.dart';
import 'src/url_scraper.dart';

class RedditSource extends ASource {
  static final Logger _log = new Logger("RedditSource");
  static final RegExp _regExp = new RegExp(
      r"https?://(www|old)\.reddit\.com/r/([^/]+)/.*",
      caseSensitive: false);
  static final RegExp _postRegexp = new RegExp(
      r"https?://(www|old)\.reddit\.com/r/([^/]+)/comments/.*",
      caseSensitive: false);
  static final RegExp _imageRegexp = new RegExp(
      r"https?://i\.(redd\.it|redditmedia\.com)/.*",
      caseSensitive: false);

  RedditSource(SettingsService settings) : super(settings) {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.image, _imageRegexp));

    this.urlScrapers
      ..add(new UrlScraper(
          _regExp, scrapeSubredditPageInfo, scrapeSubredditPageLinks))
      ..add(new UrlScraper(_imageRegexp, emptyPageScraper, selfLinkScraper));
  }

  Future<Null> scrapeSubredditPageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.finest("scrapeSubredditPageInfo");
    pageInfo
      ..saveByDefault = false
      ..artist = m.group(2);
  }

  Future<Null> scrapeSubredditPageLinks(String url, Document doc) async {
    _log.finest("scrapeSubredditPageLinks");

    final String jsonUrl = "$url.json";

    _log.finest("Fetching JSON URL: $jsonUrl");

    try {
      final dynamic jsonData = await fetchJsonData(jsonUrl);
      if (jsonData is List) {
        for (Map data in jsonData) {
          await processListingEntry(data, url);
        }
      } else if (jsonData is Map) {
        await processListingEntry(jsonData, url);
      }
    } catch(e,st) {
      _log.warning("Error while fetching reddit json",e.message, st);
    }
  }

  Future<void> processListingEntry(
      Map<String, dynamic> listingData, String url) async {
    final List<dynamic> children = listingData["data"]["children"];
    for (Map<String, dynamic> child in children) {
      final Map<String, dynamic> childData = child["data"];
      final String kind = child["kind"];
      switch (kind) {
        case "t3": //Regular post
          final String thumbnail = childData["thumbnail"];
          final String link = childData["url"];
          LinkType type = LinkType.page;

          if (childData.containsKey("media") && childData["media"] != null) {
            final Map<String, dynamic> mediaData = childData["media"];
            if (mediaData.containsKey("reddit_video")) {
              this.createAndSendLinkInfo(
                  mediaData["reddit_video"]["fallback_url"], url,
                  thumbnail: thumbnail, type: LinkType.video);
              continue;
            }
          }

          if (childData.containsKey("url") &&
              (childData["url"] ?? "").isNotEmpty) {
            await this.evaluateLink(link, url);
          }

          break;
        case "t1": //Comment
          final HtmlUnescape unescape = new HtmlUnescape();

          final String bodyHtml = unescape.convert(childData["body_html"]);
          final html.DocumentFragment bodyDoc = parseFragment(bodyHtml);

          for (html.Element aElement in bodyDoc.querySelectorAll("a")) {
            await this
                .evaluateLink(aElement.attributes["href"], url, select: false);
          }

          if (childData["replies"] is Map) {
            await processListingEntry(childData["replies"], url);
          }
          break;
        default:
          _log.warning("Unknown listing kind: $kind");
          break;
      }
    }
  }
}
