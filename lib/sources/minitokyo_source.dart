import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class MinitokyoSource extends ASource {
  static final Logger logImpl = new Logger("MinitokyoSource");

  @override
  String get sourceName => "minitokyo";

  static final RegExp _galleryRegexp = new RegExp(
      r"^https?://[^.]+\.minitokyo\.net/gallery\?.+",
      caseSensitive: false);
  static final RegExp _downloadRegexp = new RegExp(
      r"^https?://gallery\.minitokyo\.net/download/\d+",
      caseSensitive: false);
  static final RegExp _viewRegexp = new RegExp(
      r"^https?://gallery\.minitokyo\.net/view/(\d+)",
      caseSensitive: false);

  MinitokyoSource(SettingsService settings) : super(settings) {
    this
      ..urlScrapers.add(new SimpleUrlScraper(this, _downloadRegexp,
          [new SimpleUrlScraperCriteria(LinkType.image, "div#image img")]))
      ..urlScrapers.add(new UrlScraper(_viewRegexp, this.emptyPageScraper,
          (String s, Document d) {
        createAndSendLinkInfo(_translateViewToDownloadUrl(s), s,
            type: LinkType.page);
      }))
      ..urlScrapers.add(new SimpleUrlScraper(this, _galleryRegexp, [
        new SimpleUrlScraperCriteria(LinkType.page, "ul.scans li a",
            validateLinkInfo: (LinkInfo li, Element ele) {
          final ImageElement imageElement = ele.querySelector("img");
          if (imageElement == null) return false;

          li.url = _translateViewToDownloadUrl(li.url);
          return true;
        }),
        new SimpleUrlScraperCriteria(LinkType.page, "p.pagination a",
            validateLinkInfo: (LinkInfo li, Element ele) =>
                ele.text == "Next »")
      ]));
  }

  String _translateViewToDownloadUrl(String url) {
    if (_viewRegexp.hasMatch(url)) {
      logImpl.info("Redirecting view link to download link");
      final Match m = _viewRegexp.firstMatch(url);
      return "http://gallery.minitokyo.net/download/${m[1]}";
    }
    return url;
  }
}
