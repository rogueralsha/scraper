import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'package:scraper/results/page_info.dart';

import 'sources.dart';
import 'src/link_info_impl.dart';
import 'src/url_scraper.dart';

export 'package:scraper/results/page_info.dart';
export 'package:scraper/sources/src/link_info_impl.dart';

abstract class ASource {
  static final Logger _log = new Logger("ASource");

  final List<RegExp> directLinkRegexps = <RegExp>[];

  final List<UrlScraper> urlScrapers = <UrlScraper>[];

  final StreamController<dynamic> _scrapeUpdateStream =
      new StreamController<dynamic>.broadcast();

  MutationObserver galleryObserver;

  final List<String> _seenLinks = <String>[];

  ASource();

  Stream<dynamic> get onScrapeUpdateEvent => _scrapeUpdateStream.stream;
  bool get sentLinks => _seenLinks.isNotEmpty;

  Future<Null> artistFromRegExpPageScraper(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.info("artistFromRegExpPageScraper");
    pageInfo.artist = m.group(1);
  }

  bool canScrapePage(String url, {Document document}) {
    _log.finest("canScrapePage");
    for (UrlScraper us in urlScrapers) {
      if (us.isMatch(url)) return true;
    }
    return false;
  }

  void createAndSendLinkInfo(String link, String sourceUrl,
      {LinkType type= LinkType.image, String filename}) {
    if (!this._seenLinks.contains(link)) {
      this._seenLinks.add(link);
      final LinkInfo li =
          new LinkInfoImpl(link, sourceUrl, type: type, filename: filename);
      _sendLinkInfoInternal(li);
    }
  }

  bool determineIfDirectFileLink(String url) {
    for (RegExp r in this.directLinkRegexps) {
      if (r.hasMatch(url)) return true;
    }
    return false;
  }

  String determineThumbnail(String url) => null;
  Future<Null> emptyLinkScraper(String s, Document d) async {}

  Future<Null> emptyPageScraper(
      PageInfo pi, Match m, String url, Document doc) async {
    final Match m = siteRegexp.firstMatch(url);
    pi.artist = m[1];
  }

  void evaluateLink(String sourceUrl, String link, {bool select = true}) {
    _log.finest('evaluateLink($sourceUrl, $link, {$select})');
    final SupportedLinkResult result = isSupportedPage(link);
    if (result.result) {
      String thumbnail;
      if (result.thumbnail != null) {
        thumbnail = result.thumbnail;
      }
      LinkInfo li;
      if (result.directLink) {
        li = new LinkInfoImpl(link, sourceUrl,
            select: select,
            thumbnail: thumbnail,
            autoDownload: result.autoDownload);
      } else {
        li = new LinkInfoImpl(link, sourceUrl,
            type: LinkType.page,
            select: select,
            thumbnail: thumbnail,
            autoDownload: result.autoDownload);
      }
      sendLinkInfo(li);
// TODO: Make sure these get re-enabled appropriately
      //    } else if (mixtapeRegexp.test(link)||webmVideoRegexp.test(link)||armariumRegexp.test(link)||catboxRegexp.test(link)
//        ||safeMoeRegexp.test(link)||redditSource.imageRegexp.test(link)||uploaddirRegexp.test(link)||dokoMoeRegexp.test(link)
//        ||userapiRegexp.test(link)) {
//      output.addLink(createLink({url: link, type: "image", filename: filename, select: select}));
    }
  }

  Future<Null> selfLinkScraper(String url, Document d) async {
    _log.finest("selfLinkScraper");
    final LinkInfo li = new LinkInfoImpl(url, url);
    sendLinkInfo(li);
  }

  void sendLinkInfo(LinkInfo li) {
    if(li==null)
      return;
    if (!this._seenLinks.contains(li.url)) {
      this._seenLinks.add(li.url);
      _sendLinkInfoInternal(li);
    }
  }

  void sendPageInfo(PageInfo pi) {
    _log.finer("Sending PageInfo event");
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

  Future<Null> manualScrape(PageInfo pi, String url, Document document) async {}

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
      {String thumbnailSubSelector: "img", LinkType defaultLinkType: LinkType.page}) {
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
      link = ele.src;
      if (link?.isEmpty ?? true) {
        _log.finest("src attribute is empty, checking for source slements");
        final ElementList<SourceElement> sources = ele.querySelectorAll("source");
        for (SourceElement source in sources) {
          _log.finest("Source sub-element found, trying src");
          link = source.src;
          break;
        }
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
    return new LinkInfoImpl(link, sourceUrl,
        type: type, thumbnail: thumbnail);
  }

  static SupportedLinkResult isSupportedPage(String link) {
    _log.finest("isSupportedPage");

    SupportedLinkResult output = new SupportedLinkResult();
    for (ASource source in sourceInstances) {
      if (source.canScrapePage(link)) {
        output.result = true;
        output.thumbnail = source.determineThumbnail(link);
        output.directLink = source.determineIfDirectFileLink(link);
        break;
      } else if (source.determineIfDirectFileLink(link)) {
        output.result = true;
        output.thumbnail = source.determineThumbnail(link);
        output.directLink = true;
        break;
      }
    }
    if (output.result == false) {
      //TODO: Make sure these are re-enabled appropriately
//      if (hfRegExp.test(link) ||
//        flickrRegexp.test(link) ||
//        eroshareRegexp.test(link) ||
//        postimgPostRegexp.test(link) ||
//        postimgAlbumRegexp.test(link) ||
//        pimpandhostRegexp.test(link) ||
//        uploadsRuRegexp.test(link)||
//        imagebamRegexp.test(link)) {
//        output.result = true;
//      }
    }
    if (output.result == false) {
//    if (megaRegexp.test(link)||
//    googleDriveRegexp.test(link)) {
//    output.result = true;
//    output.autoDownload = false;
//    }
    }

    return output;
  }
}

class SupportedLinkResult {
  bool result = false;
  String thumbnail = null;
  bool directLink = false;
  bool autoDownload = true;
}
