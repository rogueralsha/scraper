import 'dart:async';
import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'src/url_scraper.dart';
import 'src/link_info_impl.dart';

class DeviantArtSource extends ASource {
  static final Logger _log = new Logger("DeviantArtSource");

  static final RegExp _galleryRegExp = new RegExp(
      "https?://([^\\.]+)\\.deviantart\\.com/gallery/.*",
      caseSensitive: false);
  static final RegExp _artRegExp = new RegExp(
      "https?://([^\\.]+)\\.deviantart\\.com/art/.*",
      caseSensitive: false);
  static final RegExp _sandboxRegExp =
      new RegExp("https?://sandbox\\.deviantart\\.com.*", caseSensitive: false);
  static const String _galleryItemSelector = "a.torpedo-thumb-link";

  void _scrapeNode(dynamic node, String url) {
    _log.finest("_scrapeNode($node)");
    ElementList eles = node.querySelectorAll(_galleryItemSelector);
    for (int i = 0; i < eles.length; i++) {
      Element ele = eles[i];
      ImageElement imgEle = ele.querySelector("img");
      if (ele is AnchorElement) {
        LinkInfo info = new LinkInfoImpl(ele.href, url,
            type: LinkType.page, thumbnail: imgEle.src);
        sendLinkInfo(info);
      }
    }
  }

  DeviantArtSource() {
    this
        .urlScrapers
        .add(new UrlScraper(_artRegExp, scrapeArtPageInfo, scrapeArtPageLinks));
    this.urlScrapers.add(
        new UrlScraper(_sandboxRegExp, emptyPageScraper, scrapeSandBoxLinks));
    this.urlScrapers.add(new UrlScraper(
        _galleryRegExp, scrapeGalleryPageInfo, scrapeGalleryPageLinks));
  }

  Future<Null> scrapeArtPageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.info("scrapeArtPageInfo");
    Match matches = _artRegExp.firstMatch(url);
    pageInfo.artist = matches[1];
  }

  Future<Null> scrapeArtPageLinks(String url, Document doc) async {
    _log.info("scrapeArtPageLinks");
    AnchorElement downloadEle = document.querySelector(".dev-page-download");
    if (downloadEle == null) {
      // This means the download button wasn't found
      ImageElement imgEle = document.querySelector(".dev-content-full");
      if (imgEle == null) {
        IFrameElement iFrameEle = document.querySelector("iframe.flashtime");
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
        _log.info("Found URL: " + imgEle.src);
        sendLinkInfo(new LinkInfoImpl(imgEle.src, url, type: LinkType.image));
      }
    } else {
      _log.info("Found URL: " + downloadEle.href);
      sendLinkInfo(new LinkInfoImpl(downloadEle.href, url, type: LinkType.image));
    }
  }

  Future<Null> scrapeSandBoxLinks(String url, Document doc) async {
    _log.info("scrapeSandBoxLinks");
    EmbedElement ele = document.querySelector("embed#sandboxembed");
    if (ele != null) {
      String link = ele.src;
      sendLinkInfo(new LinkInfoImpl(link, url));
    }
  }

  MutationObserver galleryObserver;
  Future<Null> scrapeGalleryPageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.info("scrapeGalleryPageInfo");
    Match m = _galleryRegExp.firstMatch(url);
    pageInfo.artist = m.group(1);
  }

  Future<Null> scrapeGalleryPageLinks(String url, Document doc) async {
    _scrapeNode(document, url);
    if (galleryObserver == null) {
      galleryObserver = new MutationObserver((List<MutationRecord> mutations, MutationObserver observer) {
        for(MutationRecord mutation in mutations) {
          if (mutation.type != "childList" || mutation.addedNodes.length == 0) {
            return;
          }
          for (int j = 0; j < mutation.addedNodes.length; j++) {
            Node node = mutation.addedNodes[j];
            _scrapeNode(node, url);
          }
        }
        sendScrapeDone();
      });
      galleryObserver.observe(document, childList: true, subtree: true);
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
