import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'package:scraper/globals.dart';
import 'src/link_info_impl.dart';
import 'src/simple_url_scraper.dart';
import 'src/url_scraper.dart';

class TinyTinyRSSSource extends ASource {
  static final Logger _log = new Logger("TinyTinyRSSSource");

  TinyTinyRSSSource();

  @override
  bool canScrapePage(String url, {Document document, bool forEvaluation = false}) {
    _log.finest("canScrapePage");
    if(document==null)
      return false;
    final List<Node> bodyEle = document.getElementsByClassName("ttrss_main");
    return bodyEle.isNotEmpty;
  }

  MutationObserver _observer;

  @override
  Future<Null> manualScrape(PageInfo pi, String url, Document document) async {
    pi.artist = siteRegexp.firstMatch(url)[1];
    pi.saveByDefault = false;


    final Element rootEle = document.querySelector("div#headlines-frame");

    if(rootEle!=null) {
      final ElementList<AnchorElement> linkElements =
      document.querySelectorAll("div#headlines-frame a.title");

      for (AnchorElement linkElement in linkElements) {
        sendLinkInfo(createLinkFromElement(linkElement, url));
      }

      if (_observer == null) {
        _observer = new MutationObserver(
                (List<MutationRecord> mutations, MutationObserver observer) {
              for (MutationRecord mutation in mutations) {
                if (mutation.type != "childList" ||
                    mutation.addedNodes.isEmpty) {
                  continue;
                }
                for (Node node in mutation.addedNodes) {
                  if (node is AnchorElement && node.classes.contains("title")) {
                    sendLinkInfo(createLinkFromElement(node, url));
                  }
                }
                break;
              }
              sendScrapeDone();
            });

        _observer.observe(rootEle, childList: true, subtree: true);
      }
    }
  }
}
