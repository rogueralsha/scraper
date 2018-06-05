import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/link_info_impl.dart';
import 'src/simple_url_scraper.dart';
import 'src/url_scraper.dart';

class DeviantArtSource extends ASource {
  static final Logger _log = new Logger("DeviantArtSource");

  static final RegExp _galleryRegExp = new RegExp(
      r"https?://([^.]+)\.deviantart\.com/gallery/.*",
      caseSensitive: false);
  static final RegExp _artRegExp = new RegExp(
      r"https?://([^.]+)\.deviantart\.com/art/.*",
      caseSensitive: false);
  static final RegExp _sandboxRegExp =
      new RegExp(r"https?://sandbox\.deviantart\.com.*", caseSensitive: false);
  static const String _galleryItemSelector = "a.torpedo-thumb-link";

  static final RegExp _imageHostRegExp = new RegExp(
      r"https?://(img|pre)\d+\.deviantart\.net/.*",
      caseSensitive: false);

  DeviantArtSource(SettingsService settings) : super(settings) {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.file, _imageHostRegExp));
    this
        .urlScrapers
        .add(new UrlScraper(_artRegExp, scrapeArtPageInfo, scrapeArtPageLinks));
    this.urlScrapers.add(
        new UrlScraper(_sandboxRegExp, emptyPageScraper, scrapeSandBoxLinks));

    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _galleryRegExp,
        <SimpleUrlScraperCriteria>[
          new SimpleUrlScraperCriteria(LinkType.page, _galleryItemSelector)
        ],
        customPageInfoScraper: scrapeGalleryPageInfo,
        watchForUpdates: true));
  }

  Future<Null> scrapeArtPageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.info("scrapeArtPageInfo");
    final Match matches = _artRegExp.firstMatch(url);
    pageInfo.artist = matches[1];
  }

  Future<Null> scrapeArtPageLinks(String url, Document doc) async {
    _log.info("scrapeArtPageLinks");
    final AnchorElement downloadEle =
        document.querySelector(".dev-page-download");
    if (downloadEle == null) {
      // This means the download button wasn't found
      final ImageElement imgEle = document.querySelector(".dev-content-full");
      if (imgEle == null) {
        final IFrameElement iFrameEle =
            document.querySelector("iframe.flashtime");
        if (iFrameEle == null) {
          _log.warning("No media found");
          return;
        } else {
          // Embedded flash file without a download button
          // TODO: Get flash files working on deviantart
          throw new Exception("Implement this when you find an example");
//          int tabId = await getCurrentTabId();
//          PageInfo response = await _getPageContentsFromIframe(tabId, iFrameEle.src);
//          if (response != null) {
//            for (int i = 0, len = response.results.length; i < len; i++) {
//              output.addResult(response.results[i]);
//            }
//          }
        }
      } else {
        _log.info("Found URL: ${imgEle.src}");
        sendLinkInfo(new LinkInfoImpl(imgEle.src, url, type: LinkType.image));
      }
    } else {
      _log.info("Found URL: ${downloadEle.href}");
      sendLinkInfo(
          new LinkInfoImpl(downloadEle.href, url, type: LinkType.image));
    }
  }

  Future<Null> scrapeGalleryPageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.info("scrapeGalleryPageInfo");
    final Match m = _galleryRegExp.firstMatch(url);
    pageInfo.artist = m.group(1);
  }

  Future<Null> scrapeGalleryPageLinks(String url, Element rootElement) async {
    _log.finest("_scrapeNode($url, $rootElement)");
    final ElementList<AnchorElement> eles =
        rootElement.querySelectorAll(_galleryItemSelector);
    for (AnchorElement ele in eles) {
      final ImageElement imgEle = ele.querySelector("img");

      final LinkInfo info = new LinkInfoImpl(ele.href, url,
          type: LinkType.page, thumbnail: imgEle.src);
      sendLinkInfo(info);
    }
  }

  Future<Null> scrapeSandBoxLinks(String url, Document doc) async {
    _log.info("scrapeSandBoxLinks");
    final EmbedElement ele = document.querySelector("embed#sandboxembed");
    if (ele != null) {
      final String link = ele.src;
      sendLinkInfo(new LinkInfoImpl(link, url));
    }
  }

//  Future<PageInfo> _getPageContentsFromIframe(int tabId, String iframeUrl) async {
//
//    PageInfo results = await  chrome.runtime
//        .sendMessage({messageFieldCommand: scrapePageCommand,
//      messageFieldTabId: tabId,
//      messageFieldUrl: iframeUrl});
//
//    if (results == null) {
//      _log.warning("No media found in iframe (null)");
//      return null;
//    }
//
//    if (results.error != null) {
//      _log.severe(results.error);
//    } else if (results.results.length == 0) {
//      _log.info("No media found in iframe");
//    } else {
//      return results;
//    }
//    return null;
//  }
}
