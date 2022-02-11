import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'a_source.dart';
import 'src/link_info_impl.dart';
import 'src/simple_url_scraper.dart';
import 'src/url_scraper.dart';
import 'dart:convert';

class PutMegaSource extends ASource {
  static final Logger _log = new Logger("PutMegaSource");

  @override
  String get sourceName => "putmega";

  static final RegExp _galleryRegExp = new RegExp(
      r"^https?://putme\.ga/album/.*",
      caseSensitive: false);

  PutMegaSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new UrlScraper(
          _galleryRegExp, scrapeArtPageInfo, scrapeNewGallery))
    ;
  }

  Future<Null> scrapeArtPageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.info("scrapeArtPageInfo");
    final Element uploaderElement = doc.querySelector("a.user-link");

    pageInfo.artist = uploaderElement?.text??"putmega";

    final Element setElement = doc.querySelector('a[data-text="album-name"]');
    pageInfo.setName = setElement?.text??"";
  }


  Future<Null> scrapeNewGallery(String url, Document doc) async {
    _log.finest("scrapeNewGallery(String url, Document doc)");

    final List<Element> itemElements = doc.querySelectorAll("div.list-item");

    for(Element ele in itemElements) {
      String jsonText = ele.dataset["object"];
      jsonText = Uri.decodeFull(jsonText);

      final Map<String, dynamic> data = json.decode(jsonText);

      if(data?.containsKey("url")) {
        this.createAndSendLinkInfo(data["url"], url);
      }


    }

  }

}
