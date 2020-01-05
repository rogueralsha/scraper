import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'package:scraper/services/page_stream_service.dart';

import 'a_source.dart';
import 'src/link_info_impl.dart';
import 'dart:convert';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;


class TumblrSource extends ASource {
  static final Logger _log = new Logger("TumblrSource");

  static final RegExp _regExp =
      new RegExp(r"https?://([^.]+)\.tumblr\.com/", caseSensitive: false);
  static final RegExp _postRegExp =
      new RegExp(r"https?://[^/]+/post/(\d+)(/.+)?", caseSensitive: false);
  static final RegExp _mobilePostRegExp =
      new RegExp(r"https?://[^/]+/post/(\d+)/mobile", caseSensitive: false);
  static final RegExp _archiveRegExp =
      new RegExp(r"https?://[^/]+/archive", caseSensitive: false);
  static final RegExp _redirectRegExp =
      new RegExp(r"redirect\?z=(.+)&t=", caseSensitive: false);

  static final RegExp _tumblrMediaRegExp =
      new RegExp(r"https?://\d+\.media\.tumblr\.com/.*", caseSensitive: false);

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
    "div#posts",
    "div.grid_7",
    "div.photoset",
    "div#entry",
    "div.entry",
    "div#root",
    "div#Body",
    "div.item"
  ];

  static final PageStreamService streamService = new PageStreamService();

  TumblrSource(SettingsService settings) : super(settings) {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.file, _tumblrMediaRegExp));
  }

  @override
  bool canScrapePage(String url,
      {Document document, bool forEvaluation = false}) {
    _log.finest("canScrapePage");

    bool possibleTumblrSite = false;

    if (_regExp.hasMatch(url)) {
      possibleTumblrSite = true;
    } else {
      if (document == null) {
        return false;
      }
      final MetaElement metaAppName =
          document.querySelector('meta[property="al:android:app_name"]');

      possibleTumblrSite = (metaAppName?.content?.toLowerCase() == "tumblr") ||
          document.querySelector("meta[name='tumblr-theme']") != null ||
          document.querySelector("meta[property='og:site_name']") != null;
    }

    if (possibleTumblrSite) {
      return _postRegExp.hasMatch(url) || _archiveRegExp.hasMatch(url);
    }
    return false;
  }

  String adjustTumblrImageUrl(String link) {
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
    return link;
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

        link = adjustTumblrImageUrl(link);

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

  MutationObserver _observer;

  void _scrapeArchiveLinks(String url) {
    final ElementList<DivElement> eles = document.querySelectorAll("div.post");
    for (DivElement postElement in eles) {
      final AnchorElement linkElement = postElement.querySelector("a.hover");
      final DivElement thumbnailElement = postElement
          .querySelector("div.post_thumbnail_container has_imageurl");
      String thumbnailSource;
      if (thumbnailElement != null) {
        thumbnailSource = thumbnailElement?.dataset["imageurl"];
      }
      createAndSendLinkInfo(linkElement.href, url,
          type: LinkType.page, thumbnail: thumbnailSource);
    }
  }

  @override
  Future<bool> manualScrape(
      PageInfo pageInfo, String url, Document document) async {
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
      _scrapeArchiveLinks(url);
      if (_observer == null) {
        _observer = new MutationObserver(
            (List<dynamic> mutations, MutationObserver observer) {
          for (MutationRecord mutation in mutations) {
            _scrapeArchiveLinks(url);
          }
        });
        _observer.observe(document, childList: true, subtree: true);
      }
    } else if (_postRegExp.hasMatch(url)) {
      _log.info("Tumblr post page");

      final String id = _postRegExp.firstMatch(url)[1];
      final String apiUrl = "${window.location.protocol}//${siteRegexp.firstMatch(url).group(1)}/api/read/json?id=$id";
      _log.finer("Fetching post json data from $apiUrl");
      String jsonString = (await fetchString(apiUrl)).substring(21).trim();
      jsonString = jsonString.substring(0,jsonString.lastIndexOf(";"));

      final Map<String,dynamic> jsonData = jsonDecode(jsonString);
      final Map<String,dynamic> postData = jsonData["posts"][0];

      _log.finest("Posts data", postData);

      if(postData["type"]=="link") {
        await evaluateLink(postData["link-url"], url);
      }

      // Extract photos
      final String photoUrl = postData["photo-url-1280"];
      if((photoUrl??"").isNotEmpty)
        createAndSendLinkInfo(photoUrl, url, type:  LinkType.image);

      if(postData.containsKey("photos")) {
        final List photos = postData["photos"];
        if (photos?.isEmpty ?? false) {
          _log.warning("Photos element not found");
        }
        if (photos != null) {
          for (Map photoData in photos) {
            final String photoDataUrl = photoData["photo-url-1280"];
            createAndSendLinkInfo(photoDataUrl, url, type: LinkType.image);
          }
        }
      }

      // Extract downloadable links
      _log.finer("photo-caption",postData["photo-caption"]);


      final List<dom.Element> anchorElements = <dom.Element>[];
      final List<dom.Element> imageElements = <dom.Element>[];

      if(postData.containsKey("photo-caption")) {
        final dom.Document postDoc = parse(postData["photo-caption"]);
        anchorElements.addAll(postDoc.querySelectorAll("a"));
        imageElements.addAll(postDoc.querySelectorAll("img"));
      }
      if(postData.containsKey("regular-body")) {
        final dom.Document postDoc = parse(postData["regular-body"]);
        anchorElements.addAll(postDoc.querySelectorAll("a"));
        imageElements.addAll(postDoc.querySelectorAll("img"));
      }
      if(postData.containsKey("answer")) {
        final dom.Document postDoc = parse(postData["answer"]);
        anchorElements.addAll(postDoc.querySelectorAll("a"));
        imageElements.addAll(postDoc.querySelectorAll("img"));
      }

      for (dom.Element linkEle in anchorElements) {
        if (_redirectRegExp.hasMatch(linkEle.attributes["href"])) {
          _log.info("Decoding redirect URL", linkEle.attributes["href"]);
          String link = _redirectRegExp.firstMatch(linkEle.attributes["href"])[1];
          link = Uri.decodeComponent(link);
          _log.info("Link decoded", link);
          await evaluateLink(link, url);
        } else {
          _log.finer("Found link element: $linkEle");
          await evaluateLink(linkEle.attributes["href"], url);
        }
      }

      for(dom.Element imgEle in imageElements) {
        if(_tumblrMediaRegExp.hasMatch(imgEle.attributes["src"])) {
          String link = imgEle.attributes["src"];
          link = adjustTumblrImageUrl(link);
          createAndSendLinkInfo(link, url, type: LinkType.image);
        } else {
          createAndSendLinkInfo(imgEle.attributes["src"], url, type: LinkType.image);
        }
      }


    }
    return true;
  }

}
