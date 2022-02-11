import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class ArtStationSource extends ASource {
  static final Logger logImpl = new Logger("ArtstationSource");

  @override
  String get sourceName => "artstation";

  static final RegExp _regExp = new RegExp(
      r"^https?://www\.artstation\.com/artwork/.*$",
      caseSensitive: false);
  static final RegExp _newRegExp = new RegExp(
      r"^https?://([^.]+)\.artstation\.com/projects/.*$",
      caseSensitive: false);
  static final RegExp _userRegExp =
      new RegExp(r"^https?://www\.artstation\.com/([^/]*)$", caseSensitive: false);

  ArtStationSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _newRegExp, [
          new SimpleUrlScraperCriteria(
              LinkType.image, "div.block-image a, div.project-assets-item a")
        ]));

    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _regExp,
        [
          new SimpleUrlScraperCriteria(LinkType.image, "div.asset-actions a",
              validateLinkInfo: (LinkInfo li, Element e) =>
                  !li.url.contains("&dl=1"))
        ],
        customPageInfoScraper: scrapeImagePageInfo));

    this.urlScrapers.add(new SimpleUrlScraper(this, _userRegExp, [
          new SimpleUrlScraperCriteria(
              LinkType.page, "div.gallery a.project-image",
              thumbnailSubSelector: "img.image")
        ]));
  }


  @override
  Future<Null> scrapingStarting(String url, Document document) async {
    for(var button in document.querySelectorAll("div.adult-content-notice button.btn-default")) {
      button.click();
    }
  }


  Future<Null> scrapeImagePageInfo(
      PageInfo pi, Match m, String s, Document doc) async {
    AnchorElement ele =
        document.querySelector('div.project-author-name a');
    pi.artist = ele.href.substring(ele.href.lastIndexOf('/') + 1);
  }
}
