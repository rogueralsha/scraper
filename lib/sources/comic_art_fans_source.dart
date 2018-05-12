import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';

class ComicArtFansSource extends ASource {
  final _log = new Logger("ComicArtFansSource");
  static final RegExp _artistRegexp = new RegExp("^https?://.+\\.comicartfans\\.com/comic\\-artists/([^\\.]+)\\.asp.*", caseSensitive: false);

  static final RegExp _pieceRegexp = new RegExp("^https?://.+\\.comicartfans\\.com/GalleryPiece.asp\\?Piece=([^&]+).+", caseSensitive: false);

  ComicArtFansSource() {
    this.urlScrapers.add(new SimpleUrlScraper(this, _pieceRegexp,
        [new SimpleUrlScraperCriteria(LinkType.image, "div#sharewrap img")]));
    this.urlScrapers.add(new SimpleUrlScraper(this, _artistRegexp, [
          new SimpleUrlScraperCriteria(LinkType.page, "div#content-left div.padding div div a",
              validateLinkElement: this.validateLinkElement),
          new SimpleUrlScraperCriteria(
              LinkType.page, "div.grey-rounded table td a",
              validateLinkElement: validatePaginationLinkElement)
        ]));
  }

  bool validateLinkElement(Element e, String url) {
    if(e is AnchorElement) {
      return _pieceRegexp.hasMatch(e.href)&&!e.href.contains("#Comment");
    }
    return false;
  }
  bool validatePaginationLinkElement(Element e, String url) => e.innerHtml.contains("Next");
}
