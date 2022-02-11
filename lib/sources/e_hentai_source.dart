import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class EHentaiSource extends ASource {
  static final Logger _log = new Logger("EHentaiSource");

  @override
  String get sourceName => "ehentai";
  static final RegExp _regExp = new RegExp(
      r"^https?://e-hentai\.org/g/.+/.+/(\?p=\d+)?$",
      caseSensitive: false);
  static final RegExp _imageRegExp = new RegExp(
      r"^https?://e-hentai\.org/s/.+/.+$",
      caseSensitive: false);
  EHentaiSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(
          this,
          _regExp,
          [
            new SimpleUrlScraperCriteria(LinkType.page, "div#gdt div.gdtm a"),
          ]))
    ..add(new SimpleUrlScraper(
    this,
        _imageRegExp,
    [
    new SimpleUrlScraperCriteria(LinkType.image, "div#i7 a, div#i3 img",
        validateLinkInfo: validateLinkInfo, limit: 1),
    ]));
  }

  bool validateLinkInfo(LinkInfo li, Element ele) {
    final Document doc = ele.ownerDocument;
    if(ele is ImageElement && doc.querySelectorAll("div#i7 a").isNotEmpty) {
      return false;
    }
    final DivElement imageInfoElement = doc.querySelector("div#i4 div");
    final String imageName =  imageInfoElement.text.split(":").first?.trim();
    li.filename = imageName;

    return true;
  }

}
