import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'package:scraper/results/page_info.dart';

import 'sources.dart';
import 'src/url_scraper.dart';
import 'src/link_info_impl.dart';

export 'package:scraper/results/page_info.dart';
export 'package:scraper/sources/src/link_info_impl.dart';

abstract class ASource {
  static final Logger _log = new Logger("ASource");

  final List<UrlScraper> urlScrapers = <UrlScraper>[];

  StreamController<dynamic> _scrapeUpdateStream =
      new StreamController<dynamic>.broadcast();

  Stream<dynamic> get onScrapeUpdateEvent => _scrapeUpdateStream.stream;

  List<String> _seenLinks = <String>[];
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

  bool determineIfDirectFileLink(String url) => false;
  String determineThumbnail(String url) => null;

  Future<Null> emptyLinkScraper(String s, Document d) async {}
  Future<Null> emptyPageScraper(
      PageInfo pi, Match m, String s, Document doc) async {}

  void evaluateLink(String sourceUrl, String link, {bool select: true}) {
    SupportedLinkResult result = isSupportedPage(link);
    if (result.result) {
      String thumbnail = null;
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
        li = new LinkInfoImpl(link,sourceUrl,
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
    LinkInfo li = new LinkInfoImpl(url, url);
    sendLinkInfo(li);
  }

  void createAndSendLinkInfo(String link, String sourceUrl, {LinkType type:  LinkType.image}) {
    LinkInfo li = new LinkInfoImpl(link, sourceUrl, type: type);
    sendLinkInfo(li);
  }

  void sendLinkInfo(LinkInfo li) {
    _log.finer("Sending LinkInfo event");
    if (!this._seenLinks.contains(li.url)) {
      this._seenLinks.add(li.url);
      _scrapeUpdateStream.add(li);
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
      _log.finest("Using url scraper: ${us.urlRegExp}");
      if (us.isMatch(url)) {
        await us.scrapePageInfo(pageInfo, url, document);
        _log.info("Artist: " + pageInfo.artist);
        sendPageInfo(pageInfo);
        await us.startLinkInfoScraping(url, document);
        sendScrapeDone();
        break;
      }
    }
  }


  Future<bool> urlExists(String url) async {
    HttpRequest request = new HttpRequest();
    request.open("HEAD", url);
    request.send();
    await for (Event e in request.onReadyStateChange) {
      if (request.readyState == HttpRequest.DONE) {
        if (request.status >= 200 && request.status <= 299) {
          return true;
        } else {
          _log.warning(request.status);
          return false;
        }
      }
    }
    return false;
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


