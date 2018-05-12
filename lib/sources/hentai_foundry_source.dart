import 'dart:async';
import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';

class HentaiFoundrySource extends ASource {
  final _log = new Logger("HentaiFoundrySource");
  static final RegExp _regExp = new RegExp(
      "https?://www\\.artstation\\.com/artwork/.*",
      caseSensitive: false);
  static final RegExp _hfRegExp = new RegExp(
      "https?://www\\.hentai-foundry\\.com/pictures/user/([^/]+)/.*",
      caseSensitive: false);
  static final RegExp _hfGalleryRegExp = new RegExp(
      "^https?://www\\.hentai-foundry\\.com/pictures/user/([^/]+)(/page/\\d+)?\$",
      caseSensitive: false);

  HentaiFoundrySource() {
    this.urlScrapers.add(new SimpleUrlScraper(this, _hfGalleryRegExp, [
          new SimpleUrlScraperCriteria(LinkType.page, "a.thumbLink", limit: 1),
          new SimpleUrlScraperCriteria(LinkType.page, "li.next a", limit: 1,
              validateLinkElement: (Element e, String url) {
            if (e is AnchorElement) {
              if (e.href != url) return true;
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
                validateLinkElement: (Element e, String url) {
              if (e is ImageElement) {
                if (e.src.contains("vote_happy.png")) return false;
                return true;
              }
              return false;
            }),
            new SimpleUrlScraperCriteria(
                LinkType.flash, "div.container div.boxbody embed")
          ],
        ));
  }
}
