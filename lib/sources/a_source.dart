import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'package:scraper/results/page_info.dart';

import 'sources.dart';
import 'src/link_info_impl.dart';
import 'src/url_scraper.dart';
import 'src/direct_link_regexp.dart';

export 'package:scraper/results/page_info.dart';
export 'package:scraper/sources/src/link_info_impl.dart';
export 'src/direct_link_regexp.dart';

abstract class ASource {
  static final Logger _log = new Logger("ASource");

  final List<DirectLinkRegExp> directLinkRegexps = <DirectLinkRegExp>[];

  final List<UrlScraper> urlScrapers = <UrlScraper>[];

  final StreamController<dynamic> _scrapeUpdateStream =
      new StreamController<dynamic>.broadcast();

  MutationObserver galleryObserver;

  final List<String> _seenLinks = <String>[];

  ASource();

  Stream<dynamic> get onScrapeUpdateEvent => _scrapeUpdateStream.stream;

  bool get sentLinks => _seenLinks.isNotEmpty;

  int get sentLinkCount => _seenLinks.length;

  Future<Null> artistFromRegExpPageScraper(
      PageInfo pageInfo, Match m, String url, Document doc,
      {int group = 1}) async {
    _log.info("artistFromRegExpPageScraper");
    pageInfo.artist = m.group(group);
  }

  bool canScrapePage(String url,
      {Document document, bool forEvaluation = false}) {
    _log.finest("canScrapePage");
    for (UrlScraper us in urlScrapers) {
      if (us.isMatch(url)) return true;
    }
    return false;
  }

  void createAndSendLinkInfo(String link, String sourceUrl,
      {LinkType type = LinkType.image, String filename, String thumbnail}) {
    if (!this._seenLinks.contains(link)) {
      this._seenLinks.add(link);
      final LinkInfo li = new LinkInfoImpl(link, sourceUrl,
          type: type, filename: filename, thumbnail: thumbnail);
      _sendLinkInfoInternal(li);
    }
  }

  String determineThumbnail(String url) => null;

  Future<Null> emptyLinkScraper(String s, Document d) async {}

  Future<Null> emptyPageScraper(
      PageInfo pi, Match m, String url, Document doc) async {
    final Match m = siteRegexp.firstMatch(url);
    pi.artist = m[1];
  }

  @protected
  Future<LinkInfo> evaluateLinkImpl(String link, String sourceUrl) async {
    _log.finest('evaluateLinkImpl($link, $sourceUrl)');
    for (DirectLinkRegExp directRegExp in this.directLinkRegexps) {
      if (directRegExp.regExp.hasMatch(link)) {
        _log.finest("Direct link regexp match found in source $this");
        String referrer;
        if(directRegExp.checkForRedirect) {
          referrer = link;
          link = await checkForRedirect(link);
        }

        final LinkInfo li = new LinkInfoImpl(link, sourceUrl,
            type: directRegExp.linkType, thumbnail: determineThumbnail(link), referrer: referrer);
        return reEvaluateLink(li, directRegExp.regExp);
      }
    }
    for (UrlScraper scraper in this.urlScrapers.where((UrlScraper us) =>
        us.useForEvaluation && us.urlRegExp.hasMatch(link))) {
      _log.finest("Compatible UrlScraper found in source $this");
      final LinkInfo li = new LinkInfoImpl(link, sourceUrl,
          type: LinkType.page, thumbnail: determineThumbnail(link));
      return reEvaluateLink(li, scraper.urlRegExp);
    }

    return null;
  }

  @protected
  LinkInfo reEvaluateLink(LinkInfo li, RegExp regExp) => li;

  Future<void> evaluateLink(String link, String sourceUrl, {bool select = true}) async {
    _log.finest('evaluateLink($link, $sourceUrl, {$select})');
    for (ASource source in sourceInstances) {
      final LinkInfo li = await source.evaluateLinkImpl(link, sourceUrl);
      if (li == null) continue;
      li.select = select;
      sendLinkInfo(li);
    }
  }

  Future<Null> selfLinkScraper(String url, Document d) async {
    _log.finest("selfLinkScraper");
    final LinkInfo li = new LinkInfoImpl(url, url);
    sendLinkInfo(li);
  }

  void sendLinkInfo(LinkInfo li) {
    if (li == null) return;
    if (!this._seenLinks.contains(li.url)) {
      this._seenLinks.add(li.url);
      _sendLinkInfoInternal(li);
    }
  }

  void sendPageInfo(PageInfo pi) {
    _log.finer("Sending PageInfo event");
    _log.finer(pi.toJson());
    _scrapeUpdateStream.add(pi);
  }

  void sendScrapeDone() {
    _log.finer("Sending scrape done signal");
    _scrapeUpdateStream.add(scrapeDoneEvent);
  }

  Future<Null> startScrapingPage(String url, Document document) async {
    _log.finest("startScrapingPage");
    _seenLinks.clear();
    final PageInfo pageInfo = new PageInfo(await getCurrentTabId());
    for (UrlScraper us in urlScrapers) {
      _log.finest("Testing url scraper: ${us.urlRegExp}");
      if (us.isMatch(url)) {
        await us.scrapePageInfo(pageInfo, url, document);
        _log.info("Artist: ${pageInfo.artist}");
        sendPageInfo(pageInfo);
        await us.startLinkInfoScraping(url, document);
        break;
      }
    }
    await manualScrape(pageInfo, url, document);

    sendScrapeDone();
  }

  Future<Null> manualScrape(
      PageInfo pageInfo, String url, Document document) async {}


  Future<String> checkForRedirect(String url) async {
    _log.finest("checkForRedirect($url)");
    final HttpRequest request = new HttpRequest()
      ..open("HEAD", url)
      ..send();
    await for (Event e in request.onReadyStateChange) {
      if (request.readyState == HttpRequest.DONE) {
        _log.fine("Response status is ${request.status}");
        if (request.status == 302) {
          _log.finer(request.responseHeaders);
          return request.responseHeaders["Location"];
        } else {
          _log.finer("Request responded from ${request.responseUrl}");
          return request.responseUrl;
        }
      }
    }
    return url;
  }

  Future<bool> urlExists(String url) async {
    final HttpRequest request = new HttpRequest()
      ..open("HEAD", url)
      ..send();
    await for (Event e in request.onReadyStateChange) {
      if (request.readyState == HttpRequest.DONE) {
        if (request.status >= 200 && request.status <= 299) {
          return true;
        } else {
          _log.fine(request.status);
          return false;
        }
      }
    }
    return false;
  }

  void _sendLinkInfoInternal(LinkInfo li) {
    if (li.url == window.location.href) {
      _log.warning("Link to current page was sent, ignoring");
      return;
    }
    _log.finer("Sending LinkInfo event");
    _scrapeUpdateStream.add(li);
  }

  LinkInfo createLinkFromElement(Element ele, String sourceUrl,
      {String thumbnailSubSelector= "img",
      LinkType defaultLinkType= LinkType.page}) {
    String link;
    String thumbnail;

    LinkType type = defaultLinkType;

    if (ele is AnchorElement) {
      _log.finest("AnchorElement found");
      link = ele.href;
      if (thumbnailSubSelector?.isNotEmpty ?? false) {
        _log.finest("Querying with $thumbnailSubSelector");
        final Element thumbEle = ele.querySelector(thumbnailSubSelector);
        if (thumbEle != null) {
          _log.info("Thumbnail element found");
          if (thumbEle is AnchorElement) {
            _log.finest("AnchorElement found for thumbnail");
            thumbnail = thumbEle.href;
          } else if (thumbEle is ImageElement) {
            _log.finest("ImageElement found for thumbnail");
            thumbnail = thumbEle.src;
          } else {
            _log.info("Unsupported element found for thumbnail, skipping");
          }
        } else {
          _log.finest("Thumbnail element not found");
        }
      }
    } else if (ele is ImageElement) {
      _log.finest("ImageElement found");
      link = ele.src;
      type = LinkType.image;
    } else if (ele is EmbedElement) {
      _log.finest("EmbedElement found");
      link = ele.src;
      type = LinkType.embedded;
    } else if (ele is VideoElement) {
      _log.finest("VideoElement found");
      type = LinkType.video;

      final ElementList<SourceElement> sources =
      ele.querySelectorAll("source");
      int highestResolution = 0;
      for (SourceElement source in sources) {
        _log.finest("Source sub-element found, trying src");
        if(source.attributes.containsKey("res")) {
          try {
            int res = int.parse(source.attributes["res"]);
            if(res>highestResolution) {
              _log.finest("Larger resolution $res than $highestResolution found, switching source");
              link = source.src;
              highestResolution = res;
            }
          } on Exception catch (e,st) {
            _log.warning("Error while parsing res attreibute on source element",e,st);
          }
        } else {
          link = source.src;
          break;
        }
      }

      if (link?.isEmpty ?? true) {
        link = ele.src;
      }
      if (link?.isEmpty ?? true) {
        _log.warning("Unable to find a source for the video element");
        return null;
      }
      if (ele.poster?.isNotEmpty ?? false) {
        _log.info("Poster attribute found, using as thumnail");
        thumbnail = ele.poster;
      }
    } else if (ele is SourceElement) {
      _log.finest("SourceElement found");
      type = LinkType.video;
      link = ele.src;
      if (ele.parent is VideoElement) {
        _log.finest("Parent element is video, checking for poster");
        final VideoElement parentEle = ele.parent;
        if (parentEle.poster?.isNotEmpty ?? false) {
          _log.info("Poster attribute found, using as thumnail");
          thumbnail = parentEle.poster;
        }
      }
    } else {
      _log.info("Unsupported element $ele found, skipping");
      return null;
    }
    if (link?.isEmpty ?? true) {
      _log.info("Null link, skipping");
      return null;
    }

    return new LinkInfoImpl(link, sourceUrl, type: type, thumbnail: thumbnail);
  }

  Future<Null> loadWholePage() async {}
}
