import 'dart:async';
import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'src/simple_url_scraper.dart';
import 'src/url_scraper.dart';

class TwitterSource extends ASource {
  static final Logger logImpl = new Logger("TwitterSource");
  static final RegExp _regExp =
      new RegExp(r"https?://twitter\.com/([^/]+)/?", caseSensitive: false);
  static final RegExp _postRegexp = new RegExp(
      r"https?://twitter\.com/([^/]+)/status/.+",
      caseSensitive: false);

  TwitterSource() {
    this.urlScrapers.add(new SimpleUrlScraper(this, _postRegexp, [
          new SimpleUrlScraperCriteria(LinkType.image,
              ".permalink-tweet-container .js-adaptive-photo img",
              validateLinkInfo: (LinkInfo li, Element e) {
            li.url = "${li.url}:large";
            return true;
          }),
          new SimpleUrlScraperCriteria(
              LinkType.video, ".permalink-tweet-container .AdaptiveMedia video")
        ]));

    this.urlScrapers.add(new UrlScraper(
        _regExp, this.artistFromRegExpPageScraper, scrapeUserPageLinks));
  }

  Future<Null> scrapeUserPageLinks(String url, Document doc) async {
    ElementList<DivElement> tweets = document.querySelectorAll("div.tweet");
    for (DivElement ele in tweets) {
      String id = ele.dataset["tweetId"];
      if (id?.isEmpty ?? true) {
        continue;
      }
      String link =
          "https://twitter.com/${_regExp.firstMatch(url)[1]}/status/$id";
      this.createAndSendLinkInfo(link, url, type: LinkType.page, filename: id);
    }
  }
}
