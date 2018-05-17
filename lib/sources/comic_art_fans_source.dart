import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'src/simple_url_scraper.dart';

class ComicArtFansSource extends ASource {
  static final Logger _log = new Logger("ComicArtFansSource");
  static final RegExp _artistRegexp = new RegExp(
      "^https?://.+\\.comicartfans\\.com/comic\\-artists/([^\\.]+)\\.asp.*",
      caseSensitive: false);

  static final RegExp _pieceRegexp = new RegExp(
      "^https?://.+\\.comicartfans\\.com/GalleryPiece.asp\\?Piece=([^&]+).+",
      caseSensitive: false);

  ComicArtFansSource() {
    this.urlScrapers.add(new SimpleUrlScraper(this, _pieceRegexp,
        [new SimpleUrlScraperCriteria(LinkType.image, "div#sharewrap img")]));
    this.urlScrapers.add(new SimpleUrlScraper(this, _artistRegexp, [
          new SimpleUrlScraperCriteria(
              LinkType.page, "div#content-left div.padding div div a",
              validateLinkInfo: this.validateLinkElement),
          new SimpleUrlScraperCriteria(
              LinkType.page, "div.grey-rounded table td a",
              validateLinkInfo: validatePaginationLinkElement)
        ]));
  }

  bool validateLinkElement(LinkInfo li, Element e) {
    _log.finest("validateLinkElement");
    if (e is AnchorElement) {
      return _pieceRegexp.hasMatch(e.href) && !e.href.contains("#Comment");
    }
    return false;
  }

  bool validatePaginationLinkElement(LinkInfo li, Element e) =>
      e.innerHtml.contains("Next");
}
