import 'dart:async';
import 'dart:html';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';
import 'src/url_scraper.dart';

class TwitterSource extends ASource {
  static final Logger logImpl = new Logger("TwitterSource");
  static final RegExp _regExp =
      new RegExp(r"https?://twitter\.com/([^/]+)/\?", caseSensitive: false);
  static final RegExp _postRegexp = new RegExp(
      r"https?://twitter\.com/([^/]+)/status/.+",
      caseSensitive: false);

  static final RegExp _imageRegexp =
      new RegExp(r"https?://pbs\.twimg\.com/media/.+", caseSensitive: false);

  TwitterSource(SettingsService settings) : super(settings) {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.image, _imageRegexp));
    this.urlScrapers
//    ..add(new UrlScraper(_postRegexp, , scrapeMetaTagLinks))
      ..add(new SimpleUrlScraper(this, _postRegexp, [
        new SimpleUrlScraperCriteria(
            LinkType.image, ".permalink-tweet-container .js-adaptive-photo img",
            validateLinkInfo: (LinkInfo li, Element e) {
          li.url = "${li.url}:large";
          return true;
        }),
        new SimpleUrlScraperCriteria(
            LinkType.video, ".permalink-tweet-container .AdaptiveMedia video")
      ]))
      ..add(new UrlScraper(
          _regExp, this.artistFromRegExpPageScraper, scrapeUserPageLinks));
  }

//og:video:url
  Future<Null> scrapeMetaTagLinks(String url, Document doc) async {
    final MetaElement meta = doc.querySelector('meta[property="og:video:url"]');
    if (meta != null) {
      final BrowserClient client = new BrowserClient();
      try {
        final http.Response response = await client.get(meta.content);
        if (response.statusCode == 200) {
        } else {
          logImpl.warning(
              "Error while fetching ${meta.content}: ${response.statusCode} - ${response.body}");
        }
      } finally {
        client.close();
      }
    }
  }

  Future<Null> scrapeUserPageLinks(String url, Document doc) async {
    final ElementList<DivElement> tweets =
        document.querySelectorAll("div.tweet");
    for (DivElement ele in tweets) {
      final String id = ele.dataset["tweetId"];
      if (id?.isEmpty ?? true) {
        continue;
      }
      final String link =
          "https://twitter.com/${_regExp.firstMatch(url)[1]}/status/$id";
      this.createAndSendLinkInfo(link, url, type: LinkType.page, filename: id);
    }
  }
}
