import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'a_source.dart';
import 'src/link_info_impl.dart';

class ShimmieSource extends ASource {
  static final Logger _log = new Logger("ShimmieSource");

  ShimmieSource();

  @override
  bool canScrapePage(String url,
      {Document document, bool forEvaluation = false}) {
    if (document == null) {
      return false;
    }
    _log.finest("canScrapePage($url, {$document}");
    final ElementList<DivElement> eles =
        document.querySelectorAll("div.shm-thumb");
    if (eles.isNotEmpty) return true;

    final Element ele = document.querySelector(".shm-main-image");
    if (ele != null) return true;

    return false;
  }

  @override
  Future<Null> manualScrape(
      PageInfo pageInfo, String url, Document document) async {
    _log.finest("manualScrape($pageInfo, $url, $document)");

    pageInfo
      ..artist = siteRegexp.firstMatch(url)[1]
      ..saveByDefault = false;

    sendPageInfo(pageInfo);

    final ElementList<DivElement> thumbnailElements =
        document.querySelectorAll("div.shm-thumb");

    if (thumbnailElements.isNotEmpty) {
      for (DivElement ele in thumbnailElements) {
        final ImageElement imgEle = ele.querySelector("img");
        final AnchorElement linkEle = ele.querySelector("a:nth-child(3)");
        final String link = linkEle.href;

        createAndSendLinkInfo(link, url,
            type: LinkType.image, thumbnail: imgEle.src);
      }
      final ElementList<AnchorElement> paginatorEles =
          document.querySelectorAll("section#paginator a");
      for (AnchorElement ele in paginatorEles) {
        if (ele.text == "Next") {
          createAndSendLinkInfo(ele.href, url, type: LinkType.page);
        }
      }
    } else {
      final Element ele = document.querySelector(".shm-main-image");
      if (ele != null) {
        sendLinkInfo(createLinkFromElement(ele, url));
      }
    }
  }
}
