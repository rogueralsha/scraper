import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'a_source.dart';
import 'src/simple_url_scraper.dart';
import 'src/url_scraper.dart';
import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

class ImgurSource extends ASource {
  static final Logger _log = new Logger("UrlScraper");

  static final RegExp   _albumRegexp= new RegExp("https?:\\/\\/([mi]\\.)?imgur\\.com\\/(a|gallery)\\/([^\\/]+)", caseSensitive: false);
  static final RegExp _postRegexp = new RegExp("https?:\\/\\/([mi]\\.)?imgur\\.com\\/([^\\/]+)\$", caseSensitive: false);
  static final RegExp   _videoRegexp= new RegExp("https?:\\/\\/([mi]\\.)?imgur\\.com\\/([^\\/]+)\.gifv\$", caseSensitive: false);
  static final RegExp   _directRegexp= new RegExp("https?:\\/\\/([mi]\\.)?imgur\\.com\\/([^\\/]+)\\.[a-z]{3,4}\$", caseSensitive: false);

  static String convertMobileUrl(String url) {
    Match m = _postRegexp.firstMatch(url);
    if(m!=null&&m.group(1) == "m.") {
        return url.replaceAll("//m.imgur.", "//imgur.");
    }
    return url;
  }

  bool canScrapePage(String url, {Document document}) {
    _log.finest("canScrapePage");
    if(inIframe()) {
      return false;
    }

    return super.canScrapePage(url, document: document);
  }

  @override
  bool determineIfDirectFileLink(String url) => (!_videoRegexp.hasMatch(url)) && _directRegexp.hasMatch(url);

  ImgurSource() {
    this.urlScrapers.add(new SimpleUrlScraper(this, _videoRegexp, [
      new SimpleUrlScraperCriteria(LinkType.video, "video", limit: 1),
    ], pif: imgurSetPageInfo));

    this.urlScrapers.add(new UrlScraper(_directRegexp,imgurSetPageInfo, this.selfLinkScraper));

    this.urlScrapers.add(new UrlScraper(_albumRegexp,scrapeAlbumPageInfo, scrapeAlbumLinkInfo));

    this.urlScrapers.add(new SimpleUrlScraper(this, _postRegexp, [
      new SimpleUrlScraperCriteria(LinkType.image, "img.post-image-placeholder, div.post-image img"),
    ], pif: scrapePostPageInfo));

  }
  Future<Null> imgurSetPageInfo (PageInfo p, Match m, String url, Document d) async {
    _log.finest("imgurSetPageInfo start");
    p.saveByDefault = false;
    p.artist = "imgur";
  }

  Future<Null> scrapePostPageInfo  (PageInfo p, Match m, String url, Document d) async {
    _log.finest("scrapePostPageInfo start");
    p.saveByDefault = false;

    TitleElement titleEle = document.querySelector("h1.post-title");
    if (titleEle != null) {
      p.artist = titleEle.text;
    } else {
      p.artist = m[2];
    }
  }

  Future<Null> scrapeAlbumPageInfo  (PageInfo p, Match m, String url, Document d) async {
    _log.finest("scrapeAlbumPageInfo start");
    p.saveByDefault = false;

    TitleElement titleEle = document.querySelector("h1.post-title");
    String albumHash = m[3];
    if (titleEle != null) {
      p.artist = titleEle.text;
    } else {
      p.artist = albumHash;
    }
  }

  Future<Null> scrapeAlbumLinkInfo(String url, Document d) {
    _log.finest("scrapeAlbumLinkInfo start");
    Completer completer = new Completer();

    String albumHash = _albumRegexp.firstMatch(url).group(3);
    _log.info("Imgur page hash: $albumHash");

    HttpRequest request = new HttpRequest();
    request.onReadyStateChange.listen((Event e) {
      if (request.readyState == HttpRequest.DONE) {
        if (request.status == 200) {
          String json = request.responseText;
          Map data = jsonDecode(json);
          List images = data["data"]["images"];

          //let links = document.querySelectorAll("img.post-image-placeholder");
          if (images != null && images.length > 0) {
            for (int j = 0; j < images.length; j++) {
              Map image = images[j];
              String  link = "http://i.imgur.com/" + image["hash"] + image["ext"];
              LinkInfo li = new LinkInfoImpl(link, url, type: LinkType.image);
              sendLinkInfo(li);
            }
          }
        } else {
          _log.severe(request.status);
        }
        completer.complete();
      }
    });

    request.open("GET", "https://imgur.com/ajaxalbums/getimages/" + albumHash + "/hit.json", async: true);
    request.send();

    return completer.future;
  }


}