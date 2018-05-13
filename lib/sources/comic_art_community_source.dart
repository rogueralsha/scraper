import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'src/simple_url_scraper.dart';

class ComicArtCommunitySource extends ASource {
  static final Logger logImpl = new Logger("ComicArtCommunitySource");
  static final RegExp _galleryRegexp = new RegExp(
      "^https?:\\/\\/.*\\.?comicartcommunity\\.com\\/gallery\\/categories.php\\?cat_id=(\\d+).*",
      caseSensitive: false);
  static final RegExp _imageRegexp = new RegExp(
      "^https?:\\/\\/.*\\.?comicartcommunity\\.com\\/gallery\\/details.php\\?image_id=(\\d+).*",
      caseSensitive: false);


  ComicArtCommunitySource() {
    this.urlScrapers.add(new SimpleUrlScraper(this, _imageRegexp,
        [new SimpleUrlScraperCriteria(LinkType.image, "div.wide center img")]));
    this.urlScrapers.add(new SimpleUrlScraper(this, _galleryRegexp, [
          new SimpleUrlScraperCriteria(LinkType.page, "tr td span a"),
          new SimpleUrlScraperCriteria(
              LinkType.page, "div.wide.column a.button.mini",
              validateLinkInfo: validatePaginationLinkElement)
        ]));
  }

  bool validatePaginationLinkElement(LinkInfo li,  Element e) => e.innerHtml.contains("»");
}
