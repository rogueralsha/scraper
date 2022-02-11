import 'dart:async';
import 'dart:html';
import 'dart:core';
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

  @override
  String get sourceName => "reddit";

  static final RegExp _regExp = new RegExp(
      r"^https?://(www|old)\.reddit\.com/r/([^/]+)/.*",
      caseSensitive: false);
  static final RegExp _postRegexp = new RegExp(
      r"^https?://(www|old)\.reddit\.com/r/([^/]+)/comments/.*",
      caseSensitive: false);
  static final RegExp _imageRegexp = new RegExp(
      r"^https?://i\.(redd\.it|redditmedia\.com)/.*",
      caseSensitive: false);
  static final RegExp _galleryRegexp = new RegExp(
      r"^https?://(www|old)\.reddit\.com/gallery/([^/]+)",
      caseSensitive: false);

  static final RegExp _imagePreviewRegexp = new RegExp(
      r"^https?://preview\.(redd\.it|redditmedia\.com)/([^?]+)\?.*",
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
    } on Exception catch(e,st) {
      _log.warning("Error while fetching reddit json $e",e, st);
    }
  }

  Future<void> processListingEntry(
      Map<String, dynamic> listingData, String url) async {
    final List<dynamic> children = listingData["data"]["children"];
    for (Map<String, dynamic> child in children) {
      Map<String, dynamic> childData = child["data"];
      final String kind = child["kind"];
      _log.finest("Child kind: $kind");

      switch (kind) {
        case "t3": //Regular post
          final String thumbnail = childData["thumbnail"];
          String link = childData["url"];
          const LinkType type = LinkType.page;


          // Check if we're dealing with a crosspost.

          if (childData.containsKey("crosspost_parent_list")
              && childData["crosspost_parent_list"] != null
              && childData["crosspost_parent_list"].length > 0) {
            _log.fine("Post is crosspost");

            childData = childData["crosspost_parent_list"][0];
          }

          if (childData.containsKey("media") && childData["media"] != null) {
            final Map<String, dynamic> mediaData = childData["media"];
            _log.fine("Post has media");
            if (mediaData.containsKey("reddit_video")) {
              _log.fine("Post has reddit video");
              this.createAndSendLinkInfo(
                  mediaData["reddit_video"]["fallback_url"], url,
                  thumbnail: thumbnail, type: LinkType.video);
              continue;
            }
          }

          if (childData.containsKey("url") &&
              (childData["url"] ?? "").isNotEmpty) {
            _log.fine("Post has url: ${childData['url']}");
            if(_imagePreviewRegexp.hasMatch(link)) {
              final Match m = _imagePreviewRegexp.firstMatch(link);
              link = "https://i.redd.it/${m.group(2)}";
              _log.finest("Link was for preview, adjusted to $link");
            }
            if(_galleryRegexp.hasMatch(link)) {
              _log.finest("Link was for gallery, skipping url submission");
            } else {
              await this.evaluateLink(link, url);
            }
          }

          if (childData.containsKey("is_gallery") &&
              (childData["is_gallery"] ?? "")==true) {

            _log.fine("Post is gallery, parsing individual images");
            //_log.finest(childData["media_metadata"]);
            final Map metadata = childData["media_metadata"];


            for(String metadataKey in metadata.keys) {
              _log.finer("Metadata key $metadataKey");
              final Map metadatum = metadata[metadataKey];
              _log.fine(metadatum);

             Map imageData;
              if(metadatum["o"]!=null) {
                imageData =metadatum["o"][0];
              } else {
                _log.warning("o entry not found");

                if(metadatum["s"]!=null) {
                  imageData =metadatum["s"];
                } else {
                  _log.warning("s entry not found");
                }
              }
                String link = imageData["u"];
                _log.finest("u: $link");

                if(link==null) {
                  _log.warning("No image data found for metadata $metadataKey");
                  continue;
                }

                _log.finest("Found gallery entry for $link");
                if(_imagePreviewRegexp.hasMatch(link)) {
                  final Match m = _imagePreviewRegexp.firstMatch(link);
                  link = "https://i.redd.it/${m.group(2)}";
                  _log.finest("Link was for preview, adjusted to $link");
                }
                await this.evaluateLink(link, url);
              }
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
