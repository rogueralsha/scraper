import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class PatreonSource extends ASource {
  static final Logger _log = new Logger("PatreonSource");

  static final RegExp _postsRegExp = new RegExp(
      r"^https?://www\.patreon\.com/([^/^?]+)/posts/?.*$",
      caseSensitive: false);
  static final RegExp _postRegExp =
      new RegExp(r"https?://www\.patreon\.com/posts/.*", caseSensitive: false);
  static final RegExp _userRegExp = new RegExp(
      r"^https?://www\.patreon\.com/([^/^?]+)$",
      caseSensitive: false);
  static final RegExp _fileRegExp = new RegExp(
      r"^https?://www\.patreon\.com/file\?[^/]+$",
      caseSensitive: false);

  PatreonSource(SettingsService settings) : super(settings) {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.file, _fileRegExp));

    this.urlScrapers
      ..add(new SimpleUrlScraper(this, _postRegExp, <SimpleUrlScraperCriteria>[
        new SimpleUrlScraperCriteria(
            LinkType.image, "div[data-tag='post-card'] img"),
        new SimpleUrlScraperCriteria(
            LinkType.page, "div[data-tag='post-card'] a",
            linkRegExp: _fileRegExp, validateLinkInfo: validatePostLinkInfo),
        new SimpleUrlScraperCriteria(
            LinkType.page, "div[data-tag='post-card'] a",
            evaluateLinks: true)
      ], customPageInfoScraper: (PageInfo pi, Match m, String s, Document doc) {
        final ElementList<AnchorElement> eles =
            document.querySelectorAll("div.sc-bZQynM a");
        for (AnchorElement ele in eles) {
          if (_userRegExp.hasMatch(ele.href)) {
            pi.artist = _userRegExp.firstMatch(ele.href)[1];
            break;
          }
        }
      }))
      ..add(new SimpleUrlScraper(
          this,
          _postsRegExp,
          <SimpleUrlScraperCriteria>[
            new SimpleUrlScraperCriteria(LinkType.page, "a",
                linkRegExp: _postRegExp),
          ],
          watchForUpdates: true,
          incrementalLoader: true));
  }

  static const String _loadMoreSelector = "button.fuSvdP";

  @override
  Future<Null> loadWholePage() async {
    window.scrollTo(0, document.body.scrollHeight);
    ButtonElement loadMoreButton = document.querySelector(_loadMoreSelector);
    while (loadMoreButton != null) {
      loadMoreButton.click();
      await pause(seconds: 2);
      window.scrollTo(0, document.body.scrollHeight);
      loadMoreButton = document.querySelector(_loadMoreSelector);
    }
    window.scrollTo(0, document.body.scrollHeight);
  }

  bool validatePostLinkInfo(LinkInfo li, Element e) {
    _log.finest("validatePostLinkInfo($li, $e)");
    if (_fileRegExp.hasMatch(li.url)) {
      li
        ..filename = e.text
        ..type = LinkType.file;
    }
    return true;
  }
}
