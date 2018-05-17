import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'a_source.dart';
import 'src/link_info_impl.dart';

class TumblrSource extends ASource {
  static final Logger _log = new Logger("TumblrSource");

  static final RegExp _regExp =
      new RegExp("https?://([^\\.]+)\\.tumblr\\.com/", caseSensitive: false);
  static final RegExp _postRegExp =
      new RegExp("https?://[^\\/]+/post/.*", caseSensitive: false);
  static final RegExp _mobilePostRegExp =
      new RegExp("https?://[^\\/]+/post/.*/mobile", caseSensitive: false);
  static final RegExp _archiveRegExp =
      new RegExp("https?://[^\\/]+/archive", caseSensitive: false);
  static final RegExp _redirectRegExp =
      new RegExp("redirect\\?z=(.+)&t=", caseSensitive: false);

  static final RegExp _tumblrMediaRegExp = new RegExp(
      "https?://\\d+\\.media\\.tumblr\\.com/.*",
      caseSensitive: false);

  static const List<String> selectors = const <String>[
    "div.main > article",
    "div.post-content",
    "div.post_content",
    "article",
    "div.init-posts article",
    "div.window",
    "div.post",
    "div.content",
    "div#content",
    "div#post",
    "div#postcontent",
    "li.post",
    "ul.post",
    "div.posts",
    "div.grid_7",
    "div.photoset",
    "div#entry",
    "div.entry",
    "div#root",
    "div#Body"
  ];

  TumblrSource() {
    this.directLinkRegexps.add(_tumblrMediaRegExp);
  }

  @override
  bool canScrapePage(String url, {Document document}) {
    _log.finest("canScrapePage");

    bool possibleTumblrSite = false;

    if(_regExp.hasMatch(url)) {
      possibleTumblrSite = true;
    } else {
      if (document == null) {
        return false;
      }
      final MetaElement metaAppName =
      document.querySelector('meta[property="al:android:app_name"]');

      possibleTumblrSite =
        (metaAppName?.content?.toLowerCase() == "tumblr") ||
        document.querySelector("meta[name='tumblr-theme']") != null;

    }

    if(possibleTumblrSite) {
      return _postRegExp.hasMatch(url)||_archiveRegExp.hasMatch(url);
    }
    return false;
  }

  Future<List<String>> getTumblrImages(String url, Element rootElement) async {
    final List<String> output = <String>[];
    final ElementList<ImageElement> elements =
        rootElement.querySelectorAll("img");
    _log.info("Found ${elements.length} img tags");
    for (ImageElement ele in elements) {
      if (ele == null) {
        _log.warning("Null element in img list");
      } else {
        String link = ele.src;
        _log.fine("Checking image", link);
        if (link.contains("avatar_")) {
          _log.fine("Tumblr avatar, skipping");
          continue;
        }
        if (!_tumblrMediaRegExp.hasMatch(link)) {
          _log.fine("Does not match tumblr regexp, skipping");
          continue;
        }

        if (link.contains("_100.")) {
          link = link.replaceAll("_100", "_1280");
        }
        if (link.contains("_500.")) {
          link = link.replaceAll("_500", "_1280");
        }
        if (link.contains("_540.")) {
          link = link.replaceAll("_540", "_1280");
        }
        if (link.contains("_250.")) {
          link = link.replaceAll("_250", "_1280");
        }
        if (link.contains("_400.")) {
          link = link.replaceAll("_400", "_1280");
        }
        _log.fine("Found URL: $link");
        final LinkInfo li = new LinkInfoImpl(link, url, type: LinkType.image);
        sendLinkInfo(li);
        if (link.contains("_1280.")) {
          link = link.replaceAll("_1280", "_raw");
          if (await this.urlExists(link)) {
            final LinkInfo li =
                new LinkInfoImpl(link, url, type: LinkType.image);
            sendLinkInfo(li);
            _log.info("Found URL: $link");
          } else {
            _log.info("URL not found: $link");
          }
        }
      }
    }
    return output;
  }


  @override
  Future<Null> manualScrape(PageInfo pageInfo, String url, Document document) async {
    _log.finest("manualScrape");

    if (_regExp.hasMatch(url)) {
      pageInfo.artist = _regExp.firstMatch(url)[1];
    } else {
      pageInfo.artist = siteRegexp.firstMatch(url)[1];
    }

    sendPageInfo(pageInfo);

    if (_archiveRegExp.hasMatch(url)) {
      _log.info("Tumblr archive page");

      // let oldHeight = 0;
      // window.scrollTo(0, document.body.scrollHeight);
      // while (oldHeight !== document.body.scrollHeight) {
      //     oldHeight = document.body.scrollHeight;
      //     await sleep(2000);
      //     window.scrollTo(0, document.body.scrollHeight);
      // }
      // window.scrollTo(0, document.body.scrollHeight);

      final ElementList<AnchorElement> links =
          document.querySelectorAll("div.post a.hover");
      for (int i = 0; i < links.length; i++) {
        final String link = links[i].href; // + "/mobile";
        createAndSendLinkInfo(link, url, type: LinkType.page);
      }
    } else if (_postRegExp.hasMatch(url)) {
      _log.info("Tumblr post page");
      if (_mobilePostRegExp.hasMatch(url)) {
        _log.info("Tumblr mobile post page");
        // Mobile page - Same code should work, but we can easily detect if it's a reblog so we can skip it
        if (document.querySelector("a.tumblr_blog") != null) {
          return;
        }
      }


      for (String selector in selectors) {
        final ElementList<Element> articles =
            document.querySelectorAll(selector);
        if (articles.isEmpty) {
          continue;
        }
        _log.info("Articles found with selector $selector");

        for (Element mainArticle in articles) {
          await getTumblrImages(url, mainArticle);

          final ElementList<AnchorElement> linkEles =
              mainArticle.querySelectorAll("a");
          for (AnchorElement linkEle in linkEles) {
            if (_redirectRegExp.hasMatch(linkEle.href)) {
              _log.info("Decoding redirect URL", linkEle.href);
              String link = _redirectRegExp.firstMatch(linkEle.href)[1];
              link = Uri.decodeComponent(link);
              _log.info("Link decoded", link);
              evaluateLink(url, link);
            }
          }

//
//            ElementList<IFrameElement> iframes = mainArticle.querySelectorAll("iframe.photoset");
//            if (iframes.isNotEmpty) {
//              _log.info("Found photoset iframes");
//              try {
//                IFrameElement iframe = iframes[0];
//                _log.info("Getting media from iframe: " + iframe.src);
//
//                let results = await getPageContentsFromIframe(iframe.src);
//                if (results != null) {
//                  for (let i = 0, len = results.length; i < len; i++) {
//                    outputData.addLink(results[i]);
//                  }
//                }
//              } catch (err, st) {
//                _log.severe("Error in the toombles",err,st);
//              }
//            }

          if (sentLinks) {
            break;
          }
        }
        if (sentLinks) {
          break;
        }
      }
    }
  }
}
