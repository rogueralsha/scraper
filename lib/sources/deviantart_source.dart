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

  @override
  String get sourceName => "deviantart";

  static final RegExp _galleryRegExp = new RegExp(
      r"^https?://([^.]+)\.deviantart\.com/gallery/.*",
      caseSensitive: false);

  static final RegExp _newGalleryRegExp = new RegExp(
      r"^https?://www\.deviantart\.com/([^/]+)/gallery/.*",
      caseSensitive: false);

  static final RegExp _artRegExp = new RegExp(
      r"^https?://([^.]+)\.deviantart\.com/art/.*",
      caseSensitive: false);

  static final RegExp _newArtRegExp = new RegExp(
      r"^https?://www\.deviantart\.com/([^/]+)/art/.+-(\d+)",
      caseSensitive: false);


  static final RegExp _newDownloadRegexp =
  new RegExp(r"^https?://www\.deviantart\.com/download/\d+/[^\-]+-[^\-]+-[^\-]+-[^\-]+-[^\-]+-[^\-]+?token=[^&]+$", caseSensitive: false);


  static final RegExp _sandboxRegExp =
      new RegExp(r"^https?://sandbox\.deviantart\.com.*$", caseSensitive: false);
  static const String _galleryItemSelector = "a[data-hook='deviation_link']";

  static final RegExp _imageHostRegExp = new RegExp(
      r"^https?://(img|pre)\d+\.deviantart\.net/.*",
      caseSensitive: false);



  DeviantArtSource(SettingsService settings) : super(settings) {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.file, _imageHostRegExp));
    this.urlScrapers
      ..add(new UrlScraper(
          _artRegExp, artistFromRegExpPageScraper, scrapeArtPageLinks))
      ..add(new UrlScraper(
          _newArtRegExp, artistFromRegExpPageScraper, scrapeNewPage))
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
//      ..add(new SimpleUrlScraper(
//          this,
//          _newGalleryRegExp,
//          <SimpleUrlScraperCriteria>[
//            new SimpleUrlScraperCriteria(LinkType.page, _galleryItemSelector)
//          ],
//          customPageInfoScraper: artistFromRegExpPageScraper,
//          watchForUpdates: true))
        ..add(new UrlScraper(
            _newGalleryRegExp, artistFromRegExpPageScraper,
            scrapeNewGallery));
    ;
  }

  Future<Null> scrapeArtPageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.info("scrapeArtPageInfo");
//    final Match matches = _artRegExp.firstMatch(url);
//    pageInfo.artist = matches[1];
  }


  Future<Null> scrapeNewGallery(String url, Document doc) async {
    _log.finest("scrapeNewGallery(String url, Document doc)");
    final Match m = _newGalleryRegExp.firstMatch(url);
    final String artist = m.group(1);
    final String dataUrl = "https://www.deviantart.com/_napi/da-user-profile/api/gallery/contents?username=$artist&limit=24&all_folder=true&mode=oldest&offset=";

    Map<String,dynamic> jsonData = await fetchJsonData("${dataUrl}0");
    List<dynamic> results = jsonData["results"];
    await processGalleryJson(results, url);
    int offset = 0;
    //var lastOffset = "";
    while(jsonData["hasMore"]==true) {
      // if(lastOffset==jsonData["nextOffset"]) {
      //   throw new Exception("Encountered repeating offset");
      // }
      // lastOffset = jsonData["nextOffset"];
      offset += results.length;
      _log.finest("There are more deviations fetching next batch at offset $offset");
      jsonData = await fetchJsonData("$dataUrl$offset");
      results = jsonData["results"];
      await processGalleryJson(results, url);
    }
  }
  Future<Null> processGalleryJson(List<dynamic> results, String referer) async {
    _log.finest("processGalleryJson(List<dynamic> $results)");
    for(Map<String,dynamic> result in results) {
      final Map<String,dynamic> deviation = result["deviation"];
      await processGalleryDeviation(deviation, referer);
    }
  }

  Future<Null> processGalleryDeviation(Map<String,dynamic> deviation, String referer) async {
    _log.finest("processGalleryDeviation(List<dynamic> $deviation)");
    final String type = deviation["type"];
    if(type=="literature") {
      return;
    }
    final String url = deviation["url"];
    final Map<String,dynamic> media = deviation["media"];
    final String baseUri = media["baseUri"];
    final String downloadable = deviation["isDownloadable"];
    final String filename = media["prettyName"];
    final List<Map> types = media["types"];
    final List<String> tokens = media["token"];
    if((types?.isNotEmpty)??false) {
      //final Map<String,dynamic> previewType = types[0];
      //String previewPath = previewType["c"];
      //previewPath = previewPath.replaceAll("<prettyName>", filename);
    }
    _log.fine("TEST");

    //final String downloadUrl = ;
    //final String thumbnail = "$baseUri/$previewPath?token=${tokens[0]}";
    createAndSendLinkInfo(url, referer, filename: filename, type: LinkType.page, delay: 5);
  }


  Future<Null> scrapeNewPage(String url, Document doc) async  {

    _log.finest("scrapeNewPage(String url, Document doc)");
    final Match m = _newArtRegExp.firstMatch(url);
    final String artist = m.group(1);
    final String id = m.group(2);
    final String dataUrl = "https://www.deviantart.com/_napi/da-browse/shared_api/deviation/extended_fetch?deviationid=$id&username=$artist&type=art&include_session=false";

    final Map<String,dynamic> jsonData = await fetchJsonData(dataUrl);
    final Map<String,dynamic> deviation = jsonData["deviation"];
    final String pageUrl = deviation["url"];
    final Map<String,dynamic> media = deviation["media"];
    final String baseUri = media["baseUri"];
    final bool downloadable = deviation["isDownloadable"];
    final String filename = media["prettyName"];
    final List<Map> types = media["types"];
    final List<String> tokens = media["token"];
//    final Map<String,dynamic> previewType = types[0];
//    String previewPath = previewType["c"];
//    previewPath = previewPath.replaceAll("<prettyName>", filename);



    String downloadUrl;
    if(downloadable) {
      final Map downloadData = deviation["extended"]["download"];
      downloadUrl = downloadData["url"];
    } else {
      final Map<String,dynamic> fullviewData = types.firstWhere((e)=>e["t"]=="fullview");
      if(fullviewData!=null&&fullviewData["c"]!=null) {
         String path =  fullviewData["c"];
        path = path.replaceAll("<prettyName>", filename);
        downloadUrl = "$baseUri/$path";
      } else {
        downloadUrl = baseUri;
      }
      if(tokens!=null&&tokens.isNotEmpty) {
        downloadUrl = "$downloadUrl?token=${tokens[0]}";
      }

    }
    //final String thumbnail = "$baseUri/$previewPath?token=${tokens[0]}";
    createAndSendLinkInfo(downloadUrl, url, filename: filename, type: LinkType.image);

  }

  static final RegExp _requestIdRegexp = new RegExp(r'"requestid":"([^"]+)"', caseSensitive: false);

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
    final List<ImageElement> imgEles = document.querySelectorAll('div.dev-view-deviation img, div[data-hook="art_stage"] img');
     ImageElement imgEle;
      String filename;
     if(imgEles.isNotEmpty) {
        imgEle = imgEles.last;
        filename = _determineFileName(imgEles.first.src);
     }

    //_log.fine("In-page image element: $imgEle");
    final AnchorElement downloadEle =
        document.querySelector('.dev-page-download, a[data-hook="download_button"]');
    if (downloadEle == null) {
      // This means the download button wasn't found
      if (imgEles.isEmpty) {
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
        sendLinkInfo(new LinkInfoImpl(this.sourceName, imgEle.src, url, type: LinkType.image, filename: filename));
      }
    } else {
//      _log.finest("Pre-redirect");
//      final String redirect = await checkForRedirect(downloadEle.href);
//      _log.finest("Post-redirect");
      final String redirect = downloadEle.href;
      _log.info("Found URL: $redirect");

      sendLinkInfo(new LinkInfoImpl(this.sourceName, redirect, url, type: LinkType.image, thumbnail: imgEle?.src));
    }
  }

  String _determineFileName(String link) {
    String filename = getFileNameFromUrl(link);
    if ((filename ?? "").isNotEmpty) {
      filename = filename.substring(0, filename.lastIndexOf("."));
      if (filename.endsWith("-pre")) {
        filename = filename.substring(0, filename.length - 4);
      }
    }
    return filename;
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

      final LinkInfo info = new LinkInfoImpl(this.sourceName, ele.href, url,
          type: LinkType.page, thumbnail: imgEle.src);
      sendLinkInfo(info);
    }
  }

  Future<Null> scrapeSandBoxLinks(String url, Document doc) async {
    _log.info("scrapeSandBoxLinks");
    final EmbedElement ele = document.querySelector("embed#sandboxembed");
    if (ele != null) {
      final String link = ele.src;
      sendLinkInfo(new LinkInfoImpl(this.sourceName, link, url));
    }
  }


}
