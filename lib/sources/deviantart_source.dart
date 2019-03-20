import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'a_source.dart';
import 'src/link_info_impl.dart';
import 'src/simple_url_scraper.dart';
import 'src/url_scraper.dart';

class DeviantArtSource extends ASource {
  static final Logger _log = new Logger("DeviantArtSource");

  static final RegExp _galleryRegExp = new RegExp(
      r"https?://([^.]+)\.deviantart\.com/gallery/.*",
      caseSensitive: false);

  static final RegExp _newGalleryRegExp = new RegExp(
      r"https?://www\.deviantart\.com/([^/]+)/gallery/.*",
      caseSensitive: false);

  static final RegExp _artRegExp = new RegExp(
      r"https?://([^.]+)\.deviantart\.com/art/.*",
      caseSensitive: false);

  static final RegExp _newArtRegExp = new RegExp(
      r"https?://www\.deviantart\.com/([^/]+)/art/.*",
      caseSensitive: false);


  static final RegExp _newDownloadRegexp =
  new RegExp(r"https?://www\.deviantart\.com/download/\d+/[^\-]+-[^\-]+-[^\-]+-[^\-]+-[^\-]+-[^\-]+?token=[^&]+", caseSensitive: false);


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
    this.urlScrapers
      ..add(new UrlScraper(
          _artRegExp, artistFromRegExpPageScraper, scrapeArtPageLinks))
      ..add(new UrlScraper(
          _newArtRegExp, artistFromRegExpPageScraper, scrapeArtPageLinks))
      ..add(
          new UrlScraper(_sandboxRegExp, emptyPageScraper, scrapeSandBoxLinks))
      ..add(new SimpleUrlScraper(
          this,
          _galleryRegExp,
          <SimpleUrlScraperCriteria>[
            new SimpleUrlScraperCriteria(LinkType.page, _galleryItemSelector)
          ],
          customPageInfoScraper: artistFromRegExpPageScraper,
          watchForUpdates: true))
      ..add(new SimpleUrlScraper(
          this,
          _newGalleryRegExp,
          <SimpleUrlScraperCriteria>[
            new SimpleUrlScraperCriteria(LinkType.page, _galleryItemSelector)
          ],
          customPageInfoScraper: artistFromRegExpPageScraper,
          watchForUpdates: true));
  }

  Future<Null> scrapeArtPageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.info("scrapeArtPageInfo");
//    final Match matches = _artRegExp.firstMatch(url);
//    pageInfo.artist = matches[1];
  }

  static final RegExp _requstIdRegexp = new RegExp(r'"requestid":"([^"]+)"', caseSensitive: false);

//  Future<Null> scrapeGalleryLinks(String url, Document doc) async {
//    for(ScriptElement script in document.querySelectorAll("script")) {
//      if(script.innerHtml.contains("__initial_body_data")) {
//        _log.fine("Candidate script: ${script.innerHtml}");
//        final String requestId = _requstIdRegexp.firstMatch(script.innerHtml).group(1);
//        //https://www.deviantart.com/dapi/v1/gallery/0?iid=597m505d104cc94dfb3717ab70950fd35b15-js0tjd65-1.1&mp=2
//
//        https://www.deviantart.com/dapi/v1/gallery/0?iid=597m1e3da45a3eda30dd5c7bbdf9c2d987fd-js0trbr5-1.1&mp=1
//
//        String response = await fetchJsonData("//https://www.deviantart.com/dapi/v1/gallery/0?iid=597m505d104cc94dfb3717ab70950fd35b15-js0tjd65-1.1&mp=2");
//
//
//        dapx > requestid
//        return;
//
//
//      }
//    }
//  }

  Future<Null> scrapeArtPageLinks(String url, Document doc) async {
    _log.info("scrapeArtPageLinks");
    final ImageElement imgEle = document.querySelector("div.dev-view-deviation img");
    _log.fine("In-page image element: $imgEle");
    final AnchorElement downloadEle =
        document.querySelector(".dev-page-download");
    if (downloadEle == null) {
      // This means the download button wasn't found
      if (imgEle == null) {
        final IFrameElement iFrameEle =
            document.querySelector("iframe.flashtime");
        if (iFrameEle == null) {
          _log.warning("No media found");
          return;
        } else {
          // Embedded flash file without a download button
          // TODO: Get flash files working on deviantart
          //throw new Exception("Implement this when you find an example");
          await ASource.streamService.requestScrapeStart(url: iFrameEle.src);
        }
      } else {
        _log.info("Found URL: ${imgEle.src}");
        sendLinkInfo(new LinkInfoImpl(imgEle.src, url, type: LinkType.image));
      }
    } else {
      _log.finest("Pre-redirect");
      final String redirect = await checkForRedirect(downloadEle.href);
      _log.finest("Post-redirect");



      _log.info("Found URL: $redirect");
      String filename;
      if(_newDownloadRegexp.hasMatch(redirect)) {
        _log.info("Download URl matches new deveiantart download format, attempting to ascertain correct file name");
        filename = await getDispositionFilename(redirect);
        // DeviantArt switched up their download links.
        // Rather than allow them all to download as "file", this will use the name if the main image file.

        if ((filename ?? "").isEmpty && imgEle != null) {
          _log.info("getting file name from image element");
          filename = getFileNameFromUrl(imgEle.src);
          if ((filename ?? "").isNotEmpty) {
            filename = filename.substring(0, filename.lastIndexOf("."));
            if (filename.endsWith("-pre")) {
              filename = filename.substring(0, filename.length - 4);
            }
          }
        }
      }

      sendLinkInfo(new LinkInfoImpl(redirect, url, type: LinkType.image, thumbnail: imgEle?.src, filename: filename));
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


}
