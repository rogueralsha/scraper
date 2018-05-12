import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'package:scraper/results/page_info.dart';

import 'sources.dart';

export 'package:scraper/results/page_info.dart';

export 'link_info_impl.dart';

typedef Future<Null> LinkInfoScraper(String s, Document d);
typedef Future<Null> PageInfoScraper(
    PageInfo pi, Match m, String s, Document d);
typedef bool ValidateLinkElement(Element e, String url);

abstract class ASource {
  static final _log = new Logger("ASource");

  final List<UrlScraper> urlScrapers = <UrlScraper>[];

  StreamController<dynamic> _scrapeUpdateStream =
      new StreamController<dynamic>.broadcast();

  Stream<dynamic> get onScrapeUpdateEvent => _scrapeUpdateStream.stream;

  Future<Null> artistFromRegExpPageScraper(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.info("artistFromRegExpPageScraper");
    pageInfo.artist = m.group(1);
  }
  bool canScrapePage(String url, {Document document}) {
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

  void evaluateLink(String link, {bool select: true}) {
    SupportedLinkResult result = isSupportedPage(link);
    if (result.result) {
      String thumbnail = null;
      if (result.thumbnail != null) {
        thumbnail = result.thumbnail;
      }
      LinkInfo li;
      if (result.directLink) {
        li = new LinkInfoImpl(link,
            select: select,
            thumbnail: thumbnail,
            autoDownload: result.autoDownload);
      } else {
        li = new LinkInfoImpl(link,
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
    LinkInfo li = new LinkInfoImpl(url);
    sendLinkInfo(li);
  }
  void sendLinkInfo(LinkInfo li) {
    _log.finer("Sending LinkInfo event");
    _scrapeUpdateStream.add(li);
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
    final PageInfo pageInfo = new PageInfo(await getCurrentTabId());
    for (UrlScraper us in urlScrapers) {
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

  static SupportedLinkResult isSupportedPage(String link) {
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

class SimpleUrlScraper extends UrlScraper {
  static final _log = new Logger("SimpleUrlScraper");
  final ASource _source;
  final List<SimpleUrlScraperCriteria> criteria;

  SimpleUrlScraper(this._source, RegExp urlRegexp, this.criteria,
      {PageInfoScraper pif: null})
      : super(urlRegexp, pif ?? _source.artistFromRegExpPageScraper, null) {
    this._linkInfoScraper = _linkInfoScraperImpl;
  }

  Future<Null> _linkInfoScraperImpl(String url, Document document) async {
    int total = 0;
    _log.finest("_linkInfoScraperImpl($url, $document) start");
    for (SimpleUrlScraperCriteria criteria in this.criteria) {
      _log.finest("Querying with ${criteria.linkSelector}");
      ElementList eles = document.querySelectorAll(criteria.linkSelector);
      _log.finest("${eles.length} elements found");
      for (Element ele in eles) {
        if (criteria.validateLinkElement != null) {
          if (!criteria.validateLinkElement(ele, url)) continue;
        }

        String link;
        String thumbnail = null;
        if (ele is AnchorElement) {
          _log.finest("AnchorElement found");
          link = ele.href;
          if (criteria.thumbnailSubSelector?.isNotEmpty ?? false) {
            _log.finest("Querying with ${criteria.thumbnailSubSelector}");
            Element thumbEle = ele.querySelector(criteria.thumbnailSubSelector);
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
        } else if(ele is EmbedElement) {
          _log.finest("EmbedElement found");
          link = ele.src;
        } else {
          _log.info("Unsupported element found, skipping");
          continue;
        }
        LinkInfo li = new LinkInfoImpl(link,
            type: criteria.linkType, thumbnail: thumbnail);
        _source.sendLinkInfo(li);
        total++;
        if(total>=criteria.limit) {
          break;
        }
      }
    }
  }
}

class SimpleUrlScraperCriteria {
  final LinkType linkType;
  final String linkSelector;
  final String thumbnailSubSelector;
  final ValidateLinkElement validateLinkElement;
  final int limit;
  SimpleUrlScraperCriteria(this.linkType, this.linkSelector,
      {this.thumbnailSubSelector: "img", this.validateLinkElement: null, this.limit: -1});
}

class SupportedLinkResult {
  bool result = false;
  String thumbnail = null;
  bool directLink = false;
  bool autoDownload = true;
}

class UrlScraper {
  static final _log = new Logger("UrlScraper");
  final RegExp _urlRegExp;
  final PageInfoScraper _pageInfoScraper;
  LinkInfoScraper _linkInfoScraper;
  UrlScraper(this._urlRegExp, this._pageInfoScraper, this._linkInfoScraper);

  bool isMatch(String url) {
    _log.finest("Checking url $url against regex $_urlRegExp");
    return _urlRegExp.hasMatch(url);
  }

  Future<Null> scrapePageInfo(
          PageInfo pageInfo, String url, Document document) =>
      this._pageInfoScraper(
          pageInfo, _urlRegExp.firstMatch(url), url, document);

  Future<Null> startLinkInfoScraping(String url, Document document) async {
    await this._linkInfoScraper(url, document);
  }
}
