import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class ComicArtCommunitySource extends ASource {
  static final Logger logImpl = new Logger("ComicArtCommunitySource");

  @override
  String get sourceName => "comic_art_community";

  static final RegExp _galleryRegexp = new RegExp(
      r"^https?://.*\.?comicartcommunity\.com/gallery/categories.php\?cat_id=(\d+).*",
      caseSensitive: false);
  static final RegExp _imageRegexp = new RegExp(
      r"^https?://.*\.?comicartcommunity\.com/gallery/details.php\?image_id=(\d+).*",
      caseSensitive: false);

  ComicArtCommunitySource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _imageRegexp, [
          new SimpleUrlScraperCriteria(LinkType.image, "div.wide center img",
              limit: 1)
        ]));
    this.urlScrapers.add(new SimpleUrlScraper(this, _galleryRegexp, [
          new SimpleUrlScraperCriteria(LinkType.page, "tr td span a"),
          new SimpleUrlScraperCriteria(
              LinkType.page, "div.wide.column a.button.mini",
              validateLinkInfo: validatePaginationLinkElement)
        ]));
  }

  bool validatePaginationLinkElement(LinkInfo li, Element e) =>
      e.innerHtml.contains("»");
}
