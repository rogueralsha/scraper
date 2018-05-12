import 'dart:async';
import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'src/link_info_impl.dart';

class ShimmieSource extends ASource {
  static final Logger _log = new Logger("ShimmieSource");

  ShimmieSource() {
  }
  @override
  bool canScrapePage(String url, {Document document}) {
    if(document==null) {
      return false;
    }
    _log.finest("canScrapePage($url, {$document}");
    ElementList eles = document.querySelectorAll("div.shm-thumb");
    if(eles.isNotEmpty)
      return true;

    Element ele = document.querySelector(".shm-main-image");
    if(ele!=null)
      return true;

    return false;
  }


  @override
  Future<Null> startScrapingPage(String url, Document document) async {
    _log.finest("startScrapingPage($url, {$document}");
    final PageInfo pageInfo = new PageInfo(await getCurrentTabId());
    pageInfo.artist = siteRegexp.firstMatch(url)[1];
    pageInfo.saveByDefault = false;
    sendPageInfo(pageInfo);

    ElementList eles = document.querySelectorAll("div.shm-thumb");

    if (eles.length > 0) {
      _log.info("Shimmie site detected");
      sendPageInfo(pageInfo);
      for(Element ele in eles) {
        ImageElement imgEle = ele.querySelector("img");
        AnchorElement linkEle = ele.querySelector("a:nth-child(3)");
        String link = linkEle.href;

        LinkInfo li = new LinkInfoImpl(link, url, type: LinkType.image, thumbnail: imgEle.src);
        sendLinkInfo(li);
      }
      eles = document.querySelectorAll("section#paginator a");
      if (eles != null) {
        for(AnchorElement ele in eles) {
          if (ele.text == "Next") {
            LinkInfo li = new LinkInfoImpl(ele.href, url, type: LinkType.page);
            sendLinkInfo(li);
          }
        }
      }


    } else {
      Element ele = document.querySelector(".shm-main-image");
      if (ele != null) {
        LinkInfo link;
        if (ele is ImageElement) {
          link = new LinkInfoImpl(ele.src, url, type: LinkType.image);
          sendLinkInfo(link);
        } else if (ele is VideoElement) {
          SourceElement sourceElement = ele.querySelector("source");
          link = new LinkInfoImpl(sourceElement.src, url, type: LinkType.video);
          sendLinkInfo(link);
        }
        sendLinkInfo(link);
      }
    }

  }


}