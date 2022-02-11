import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class PinupfilesSource extends ASource {
  static final Logger _log = new Logger("PinupfilesSource");

  @override
  String get sourceName => "pinup_files";

  static final RegExp _modelRegExp = new RegExp(
      r"^https?://www\.pinupfiles\.com/members/models/([^/^?]+).html$",
      caseSensitive: false);

  static final RegExp _photosRegExp = new RegExp(
      r"^https?://www\.pinupfiles\.com/members/scenes/([^/^?]+).html$",
      caseSensitive: false);

  static final RegExp _videoDownloadRegExp =
      new RegExp(r"([^(]+)\(([\d.]+) MB\)$", caseSensitive: false);

  PinupfilesSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(this, _modelRegExp, <SimpleUrlScraperCriteria>[
        new SimpleUrlScraperCriteria(
            LinkType.page, "div.inner-area div.item-info h4 a"),
      ]))
      ..add(new UrlScraper(
          _photosRegExp, this.emptyPageScraper, this.downloadScenes));
  }

  Future<Null> downloadScenes(String url, Document doc) async {
    _log.finest("start downloadScenes($url, $doc)");
    // Photo download
    final List<OptionElement> eles =
        doc.querySelectorAll("span.select_download option");
    if (eles.isNotEmpty) {
      final OptionElement lastEle = eles.last;
      this.createAndSendLinkInfo(
          "https://www.pinupfiles.com${lastEle.value}", url,
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
      Match m = _videoDownloadRegExp.firstMatch(a.text);
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
