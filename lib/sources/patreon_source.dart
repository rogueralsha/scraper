import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class PatreonSource extends ASource {
  static final Logger _log = new Logger("PatreonSource");

  @override
  String get sourceName => "patreon";

  static final RegExp _postsRegExp = new RegExp(
      r"^https?://www\.patreon\.com/([^/^?]+)/posts/?.*$",
      caseSensitive: false);

  static final RegExp _otherPostsRegExp = new RegExp(
      r"^https?://www\.patreon\.com/user/posts\?u=(\d+).*$",
      caseSensitive: false);

  static final RegExp _numericUserLinkRegExp = new RegExp(
      r"^https?://www\.patreon\.com/user\?u=(\d+).*$",
      caseSensitive: false);



  static final RegExp _postRegExp =
      new RegExp(r"^https?://www\.patreon\.com/posts/.*$", caseSensitive: false);


  static final RegExp _userRegExp = new RegExp(
      r"^https?://www\.patreon\.com/([^/^?]+)$",
      caseSensitive: false);


  static final RegExp _fileRegExp = new RegExp(
      r"^https?://www\.patreon\.com/file\?[^/]+$",
      caseSensitive: false);

  static final RegExp _postDataRegExp = new RegExp(
      r"Object.assign\(window.patreon.bootstrap, ({(\s|.)+?})\);",
      caseSensitive: false);

  PatreonSource(SettingsService settings) : super(settings) {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.file, _fileRegExp));

    this.urlScrapers
      ..add(new UrlScraper(_postRegExp, pageInfoScraper, linkInfoScraper))
      ..add(new SimpleUrlScraper(
          this,
          _postRegExp,
          <SimpleUrlScraperCriteria>[
            //new SimpleUrlScraperCriteria(
            //  LinkType.image, "div[data-tag='post-card'] img"),
            new SimpleUrlScraperCriteria(
                LinkType.page, "div[data-tag='post-card'] a",
                linkRegExp: _fileRegExp,
                validateLinkInfo: validatePostLinkInfo),
            new SimpleUrlScraperCriteria(
                LinkType.page, "div[data-tag='post-card'] a",
                evaluateLinks: true),
            new SimpleUrlScraperCriteria(
                LinkType.image, "div[data-tag='post-content'] img"),
          ],
          customPageInfoScraper: pageInfoScraper))
      ..add(new SimpleUrlScraper(
          this,
          _postsRegExp,
          <SimpleUrlScraperCriteria>[
            new SimpleUrlScraperCriteria(LinkType.page, "a",
                linkRegExp: _postRegExp),
          ],
          watchForUpdates: true,
          incrementalLoader: true))
      ..add(new SimpleUrlScraper(
          this,
          _otherPostsRegExp,
          <SimpleUrlScraperCriteria>[
            new SimpleUrlScraperCriteria(LinkType.page, "a",
                linkRegExp: _otherPostsRegExp),
          ],
          watchForUpdates: true,
          incrementalLoader: true))

    ;
  }

  static const String _loadMoreSelector = "button.fuSvdP";

  Future<Null> pageInfoScraper(
      PageInfo pi, Match m, String s, Document doc) async {

    final ElementList<AnchorElement> eles = document.querySelectorAll(
        "div#renderPageContentWrapper >div >div >div> div > div > div > div > a");
    for (AnchorElement ele in eles) {
      if (_numericUserLinkRegExp.hasMatch(ele.href)) {
        pi.artist = _numericUserLinkRegExp.firstMatch(ele.href)[1];
        break;
      } else if (_userRegExp.hasMatch(ele.href)) {
        pi.artist = _userRegExp.firstMatch(ele.href)[1];
        break;
      }
    }
  }

  Future<Null> linkInfoScraper(String s, Document d) async {
    _log.finest("linkInfoScraper($s,Document) start");
    try {
      final String pageData = await this.fetchString(s);
      if (_postDataRegExp.hasMatch(pageData)) {
        final Match m = _postDataRegExp.firstMatch(pageData);
        final String dataString = m.group(1);
        final Map data = jsonDecode(dataString);
        final Map postdata = data["post"];
        if (postdata.containsKey("included")) {
          final List included = postdata["included"];
          for (Map item in included) {
            if (item["type"] != "media") {
              continue;
            }
            final String link = item["attributes"]["download_url"];
            final String filename = item["attributes"]["file_name"];

            this.createAndSendLinkInfo(link, s,
                thumbnail: item["attributes"]["image_urls"]["thumbnail"],
                filename: filename);
          }
        } else {
          _log.fine("No included data found found");
        }
      } else {
        _log.fine("No post JSON found");
      }
    } finally {
      _log.finest("linkInfoScraper end");
    }
  }

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
