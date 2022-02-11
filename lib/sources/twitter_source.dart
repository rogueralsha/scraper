import 'dart:async';
import 'dart:html';
import 'package:meta/meta.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';
import 'src/url_scraper.dart';

class TwitterSource extends ASource {
  static final Logger logImpl = new Logger("TwitterSource");

  @override
  String get sourceName => "twitter";

  static final RegExp _regExp =
      new RegExp(r"^https?://twitter\.com/([^/]+)/?\??$", caseSensitive: false);
  static final RegExp _postRegexp = new RegExp(
      r"^https?://twitter\.com/([^/]+)/status/.+",
      caseSensitive: false);

  static final RegExp _imageRegexp =
    new RegExp(r"^https?://pbs\.twimg\.com/media/.+$", caseSensitive: false);
  static final RegExp _newImageRegexp =
    new RegExp(r"^(https?://pbs\.twimg\.com/media/[^?]+)\?format=.+$", caseSensitive: false);


  static final RegExp _redirectRegexp =
    new RegExp(r"^https?://t\.co/.+$", caseSensitive: false);

  // article: article.r-1udh08x

  TwitterSource(SettingsService settings) : super(settings) {
    this.directLinkRegexps
        ..add(new DirectLinkRegExp(LinkType.image, _imageRegexp))
        ..add(new DirectLinkRegExp(LinkType.page, _redirectRegexp, checkForRedirect: true));
    this.urlScrapers
      ..add(new SimpleUrlScraper(this, _postRegexp, [
        new SimpleUrlScraperCriteria( // Old gui
            LinkType.image, ".permalink-tweet-container .js-adaptive-photo img",

            validateLinkInfo: (LinkInfo li, Element e) {
              li.url = "${li.url}:orig";
              return true;
            }),
        new SimpleUrlScraperCriteria(
            LinkType.video, ".permalink-tweet-container .AdaptiveMedia video"),
        new SimpleUrlScraperCriteria(LinkType.page, "div.js-tweet-text-container a",
            linkAttribute: "data-expanded-url",evaluateLinks: true),
        new ManualUrlScraperCriteria(selfLinkScraper)
      ],
          customPageInfoScraper: artistFromRegExpPageScraper
      ),

      )
      ..add(new UrlScraper(
          _regExp, this.artistFromRegExpPageScraper, scrapeUserPageLinks));
  }

  @override
  Future<Null> selfLinkScraper(String url, Document d) async {
    logImpl.finest("selfLinkScraper");

    final articles = document.querySelectorAll("article[role='article']");
    logImpl.fine("${articles.length} articles found");
    for(var article in articles) {
      
      if(article.querySelectorAll("span").any((e)=>e.text=="Retweets and comments"||e.text=="Retweets")) {
        logImpl.fine("Retweet span found, checking for images");
        final List<Element> imgs = article.querySelectorAll("img");
        logImpl.fine("${imgs.length} Image elementcs found");
        for(ImageElement img in imgs) {
          if(_newImageRegexp.hasMatch(img.src)) {
            final Match m = _newImageRegexp.firstMatch(img.src);

            final String url = "${m.group(1)}?format=png&name=large";
            final LinkInfo li = new LinkInfoImpl(this.sourceName, url, url, type: LinkType.image);
            sendLinkInfo(li);
          }
        }
        final List<AnchorElement> as = article.querySelectorAll("a");
        for(AnchorElement a in as) {
          await this.evaluateLink(a.href, url);
        }

        break;
      }
    }


  }


  @override
  Future<Null> scrapingStarting(String url, Document document) async {
    for(var button in document.querySelectorAll("button.js-display-this-media")) {
      button.click();
    }
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
      final String id = ele.dataset["tweet-id"];
      if (id?.isEmpty ?? true) {
        continue;
      }
      final String link =
          "https://twitter.com/${_regExp.firstMatch(url)[1]}/status/$id";
      this.createAndSendLinkInfo(link, url, type: LinkType.page, filename: id);
    }
  }

  }
