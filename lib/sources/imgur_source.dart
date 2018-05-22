import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';
import 'src/url_scraper.dart';

class ImgurSource extends ASource {
  static final Logger _log = new Logger("ImgurSource");

  static final RegExp _albumRegexp = new RegExp(
      "https?:\\/\\/([mi]\\.)?imgur\\.com\\/(a|gallery)\\/([^\\/]+)",
      caseSensitive: false);
  static final RegExp _postRegexp = new RegExp(
      "https?:\\/\\/([mi]\\.)?imgur\\.com\\/([^\\/]+)\$",
      caseSensitive: false);
  static final RegExp _videoRegexp = new RegExp(
      "https?:\\/\\/([mi]\\.)?imgur\\.com\\/([^\\/]+)\.gifv\$",
      caseSensitive: false);
  static final RegExp _directRegexp = new RegExp(
      "https?:\\/\\/([mi]\\.)?imgur\\.com\\/([^\\/]+)\\.(jpg|png)(\\?.+)?\$",
      caseSensitive: false);

  ImgurSource() {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.image, _directRegexp));

    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _videoRegexp,
        [
          new SimpleUrlScraperCriteria(LinkType.video, "video", limit: 1),
        ],
        customPageInfoScraper: imgurSetPageInfo));

    this.urlScrapers.add(
        new UrlScraper(_directRegexp, imgurSetPageInfo, this.selfLinkScraper));

    this.urlScrapers.add(new UrlScraper(
        _albumRegexp, scrapeAlbumPageInfo, scrapeAlbumLinkInfo,
        useForEvaluation: true));

    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _postRegexp,
        [
          new SimpleUrlScraperCriteria(
              LinkType.image, "img.post-image-placeholder, div.post-image img"),
          new SimpleUrlScraperCriteria(LinkType.video, "div.post-image video"),
        ],
        customPageInfoScraper: scrapePostPageInfo,
        useForEvaluation: true));
  }

  @override
  bool canScrapePage(String url,
      {Document document, bool forEvaluation = false}) {
    _log.finest("canScrapePage");
    if (inIframe()) {
      return false;
    }

    return super
        .canScrapePage(url, document: document, forEvaluation: forEvaluation);
  }

  Future<Null> imgurSetPageInfo(
      PageInfo p, Match m, String url, Document d) async {
    _log.finest("imgurSetPageInfo start");
    p
      ..saveByDefault = false
      ..artist = "imgur";
  }

  Future<Null> scrapeAlbumLinkInfo(String url, Document d) {
    _log.finest("scrapeAlbumLinkInfo start");
    final Completer<Null> completer = new Completer<Null>();

    final String albumHash = _albumRegexp.firstMatch(url).group(3);
    _log.info("Imgur page hash: $albumHash");

    final HttpRequest request = new HttpRequest();
    request.onReadyStateChange.listen((Event e) {
      if (request.readyState == HttpRequest.DONE) {
        if (request.status == 200) {
          _log.finer("Response received");
          final String json = request.responseText;
          _log.finer(json);
          final Map<String, dynamic> data = jsonDecode(json);
          if (data["data"] is Map && data["data"].containsKey("images")) {
            _log.finest("Images map found in data, processing");
            final List<Map> images = data["data"]["images"];

            //let links = document.querySelectorAll("img.post-image-placeholder");
            for (Map image in images) {
              final String link =
                  "http://i.imgur.com/${image['hash']}${image['ext']}";
              final LinkInfo li =
                  new LinkInfoImpl(link, url, type: LinkType.image);
              sendLinkInfo(li);
            }
          } else {
            _log.finest(
                "Images map not found in data, getting images manually");
            // This can happen on some single-image pages
            final ElementList<DivElement> eles =
                document.querySelectorAll("div.post-image");
            for (DivElement postElement in eles) {
              final Element ele = postElement.querySelector("a") ??
                  postElement.querySelector("img");
              sendLinkInfo(createLinkFromElement(ele, url,
                  defaultLinkType: LinkType.image));
            }
          }
        } else {
          _log.severe(request.status);
        }
        completer.complete();
      }
    });

    request
      ..open(
        "GET", "https://imgur.com/ajaxalbums/getimages/$albumHash/hit.json",
        async: true)
      ..send();

    return completer.future;
  }

  Future<Null> scrapeAlbumPageInfo(
      PageInfo p, Match m, String url, Document d) async {
    _log.finest("scrapeAlbumPageInfo start");
    p.saveByDefault = false;

    final AnchorElement posterElement =
        document.querySelector("a.post-account");
    final TitleElement titleEle = document.querySelector("h1.post-title");
    final String albumHash = m[3];
    p.artist = posterElement?.text ?? titleEle?.text ?? albumHash;
  }

  Future<Null> scrapePostPageInfo(
      PageInfo p, Match m, String url, Document d) async {
    _log.finest("scrapePostPageInfo start");
    p.saveByDefault = false;
    final AnchorElement posterElement =
        document.querySelector("a.post-account");
    final TitleElement titleEle = document.querySelector("h1.post-title");
    p.artist = posterElement?.text ?? titleEle?.text ?? m[2];
  }

  static String convertMobileUrl(String url) {
    final Match m = _postRegexp.firstMatch(url);
    if (m != null && m.group(1) == "m.") {
      return url.replaceAll("//m.imgur.", "//imgur.");
    }
    return url;
  }
}
