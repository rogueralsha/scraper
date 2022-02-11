import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class HaruhiskySource extends ASource {
  static final Logger _log = new Logger("HaruhiskySource");

  @override
  String get sourceName => "haruhisky";
  static final RegExp _regExp = new RegExp(
      r"^https?://(www\.)?haruhisky\.com/gallery/\d+",
      caseSensitive: false);

  static final RegExp _imageRegExp = new RegExp(
      r"^https?://(www\.)?haruhisky\.com/gallery/\d+/(\d+)",
      caseSensitive: false);

  HaruhiskySource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(
          this,
          _regExp,
          [
            new SimpleUrlScraperCriteria(LinkType.image, "div.GalleryContent_imagesdiv__1D_3h a", validateLinkInfo:
                (LinkInfo li, Element e) {
                if (e is AnchorElement) {
                  _log.finer("Found URL: ${e.href}");
                  final Match m = _imageRegExp.firstMatch(e.href);
                  if(m!=null) {
                    _log.finer("Found match: ${m.group(2)}");
                    li.url = "https://haruhisky.com:3333/image/${m.group(2)}";
                    return true;
                  }
                }
                return false;
              })
          ],
          customPageInfoScraper: scrapePageInfo));
  }

  Future<Null> scrapePageInfo(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.finest("scrapePageInfo");

    await this.emptyPageScraper(pageInfo, m, url, doc);

    final Element title = document.querySelector("div.GalleryPage_title__1pO9L");
    if(title!=null) {
      pageInfo.setName = title.text;
    }

    pageInfo.saveByDefault = false;
  }
}
