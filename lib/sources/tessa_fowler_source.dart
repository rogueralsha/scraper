import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class TessaFowlerSource extends ASource {
  static final Logger _log = new Logger("TessaFowlerSource");

  @override
  String get sourceName => "tessa_fowler_source";

  static final RegExp _categoriesRegExp = new RegExp(
      r"^https?://www\.tessafowler\.com/members/categories/.+$",
      caseSensitive: false);


  static final RegExp _photosRegExp = new RegExp(
      r"^https?://www\.tessafowler\.com/members/scenes/([^/^?]+).html$",
      caseSensitive: false);

  static final RegExp _videoDownloadRegExp =
      new RegExp(r"([^(]+)\(([\d.]+) MB\)$", caseSensitive: false);

  TessaFowlerSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(this, _categoriesRegExp, <SimpleUrlScraperCriteria>[
        new SimpleUrlScraperCriteria(
            LinkType.page, "div.item-updates div.item-title a"),
      ]))
      ..add(new UrlScraper(
          _photosRegExp, this.emptyPageScraper, this.downloadScenes));
  }

  Future<Null> downloadScenes(String url, Document doc) async {
    _log.finest("start downloadScenes($url, $doc)");
    // Photo download
    final List<AnchorElement> eles =
        doc.querySelectorAll("div.player_options  span.options_button ul li a");
    if (eles.isNotEmpty) {
      final AnchorElement lastEle = eles.last;
      this.createAndSendLinkInfo(
          lastEle.href,  url,
          type: LinkType.file);
    }

    // Video download
    final List<AnchorElement> videoDownloadEles =
        doc.querySelectorAll("ul.downloaddropdown li a");
    bool fullSizeFound = false;
    String candidateLink;
    double candidateSize = 0.0;
    _log.fine("Video download elements found: ${videoDownloadEles.length}");
    for (AnchorElement a in videoDownloadEles) {
      String anchorText = a.text?.trim();
      _log.fine("Anchor text: $anchorText");
      Match m = _videoDownloadRegExp.firstMatch(anchorText);
      if(m==null) {
        continue;
      }
      String description = m[1].trim();
      String sizeText = m[2].trim();
      _log.finer("Description: $description; Size: $sizeText");
      double size = double.parse(sizeText);
      _log.finer("Parsed size: $size");
      if (description.contains("Source")) {
        if (!fullSizeFound || size > candidateSize) {
          candidateLink = a.href;
          candidateSize = size;
        }
        fullSizeFound = true;
      } else {
        if (fullSizeFound) continue;

        if (size > candidateSize) {
          candidateLink = a.href;
          candidateSize = size;
        }
      }
    }
    if (candidateLink != null) {
      this.createAndSendLinkInfo(candidateLink, url, type: LinkType.video);
    }

    _log.finest("end downloadScenes($url, $doc)");
  }
}
