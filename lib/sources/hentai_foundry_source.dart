import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class HentaiFoundrySource extends ASource {
  static final Logger logImpl = new Logger("HentaiFoundrySource");

  @override
  String get sourceName => "hentai_foundry";

  static final RegExp _hfRegExp = new RegExp(
      r"^https?://www\.hentai-foundry\.com/pictures/user/([^/]+)/.*",
      caseSensitive: false);
  static final RegExp _hfGalleryRegExp = new RegExp(
      r"^https?://www\.hentai-foundry\.com/pictures/user/([^/]+)(/page/\d+)?$",
      caseSensitive: false);

  HentaiFoundrySource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _hfGalleryRegExp, [
          new SimpleUrlScraperCriteria(LinkType.page, "a.thumbLink"),
          new SimpleUrlScraperCriteria(LinkType.page, "li.next a", limit: 1,
              validateLinkInfo: (LinkInfo li, Element e) {
            if (e is AnchorElement) {
              if (e.href != li.sourceUrl) return true;
            }
            return false;
          })
        ]));

    this.urlScrapers.add(new SimpleUrlScraper(
          this,
          _hfRegExp,
          [
            new SimpleUrlScraperCriteria(
                LinkType.image, "div.container div.boxbody img",
                validateLinkInfo: (LinkInfo li, Element e) {
              if (e is ImageElement) {
                if (e.src.contains("vote_happy.png")) return false;
                return true;
              }
              return false;
            }, limit: 1),
            new SimpleUrlScraperCriteria(
                LinkType.flash, "div.container div.boxbody embed")
          ],
        ));
  }
}
