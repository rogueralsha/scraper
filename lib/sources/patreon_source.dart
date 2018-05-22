import 'dart:async';
import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'src/simple_url_scraper.dart';

class PatreonSource extends ASource {
  static final Logger _log = new Logger("PatreonSource");

  static final RegExp _postsRegExp = new RegExp(
      r"^https?:\/\/www\.patreon\.com/([^\/^?]+)\/posts\/?.*$",
      caseSensitive: false);
  static final RegExp _postRegExp = new RegExp(
      r"https?:\/\/www\.patreon\.com\/posts\/.*",
      caseSensitive: false);
  static final RegExp _userRegExp = new RegExp(
      r"^https?:\/\/www\.patreon\.com\/([^\/^?]+)$",
      caseSensitive: false);
  static final RegExp _fileRegExp = new RegExp(
      r"^https?:\/\/www\.patreon\.com\/file\?[^\/]+$",
      caseSensitive: false);

  PatreonSource() {
    this.directLinkRegexps.add(new DirectLinkRegExp(LinkType.file,_fileRegExp));

    this
        .urlScrapers
        .add(new SimpleUrlScraper(this, _postRegExp, <SimpleUrlScraperCriteria>[
          new SimpleUrlScraperCriteria(
              LinkType.image, "div[data-tag='post-card'] img"),
          new SimpleUrlScraperCriteria(LinkType.page, "a",
              linkRegExp: _fileRegExp, validateLinkInfo: validatePostLinkInfo),
          new SimpleUrlScraperCriteria(LinkType.page, "a",
              evaluateLinks: true)
        ], customPageInfoScraper: (PageInfo pi, Match m, String s, Document doc) {
          final ElementList<AnchorElement> eles =
              document.querySelectorAll("div.mb-md a");
          for (AnchorElement ele in eles) {
            if (_userRegExp.hasMatch(ele.href)) {
              pi.artist = _userRegExp.firstMatch(ele.href)[1];
            }
          }
        }));

    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _postsRegExp,
        <SimpleUrlScraperCriteria>[
          new SimpleUrlScraperCriteria(LinkType.page, "a",
              linkRegExp: _postRegExp),
        ],
        watchForUpdates: true));
  }
  bool validatePostLinkInfo(LinkInfo li, Element e) {
    _log.finest("validatePostLinkInfo($li, $e)");
    if (_fileRegExp.hasMatch(li.url)) {
      li.filename = e.text;
      li.type = LinkType.file;
    }
    return true;
  }

  //
//  window.scrollTo(0, document.body.scrollHeight);
//  let loadMoreButton = document.querySelector("button.bXKbjO");
//  while (loadMoreButton != null) {
//  loadMoreButton.click();
//  await sleep(2000);
//  window.scrollTo(0, document.body.scrollHeight);
//  loadMoreButton = document.querySelector("button.bXKbjO");
//  }
//  window.scrollTo(0, document.body.scrollHeight);

}
