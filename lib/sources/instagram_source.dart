import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class InstagramSource extends ASource {
  static final Logger logImpl = new Logger("InstagramSource");

  static final RegExp _regExp =
      new RegExp(r"https?://www\.instagram\.com/p/.*", caseSensitive: false);
  static final RegExp _userRegExp = new RegExp(
      r"https?://www\.instagram\.com/([^/]+)/",
      caseSensitive: false);

  static final RegExp _metaUserRegexp = new RegExp(r"@([^ )]+)");

  static final RegExp _contentRegExp =
      new RegExp(r"https?://[^.]+\.cdninstagram\.com/.+", caseSensitive: false);

  InstagramSource(SettingsService settings) : super(settings) {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.file, _contentRegExp));

    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _regExp,
        [
          new SimpleUrlScraperCriteria(
              LinkType.image, "section main div article div div div div img"),
          new SimpleUrlScraperCriteria(LinkType.video, "video")
        ],
        customPageInfoScraper: scrapePostPageInfo));

    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _userRegExp,
        [
          new SimpleUrlScraperCriteria(
              LinkType.image, "span section main article div div div div a")
        ],
        customPageInfoScraper: scrapeUserPageInfo,
        watchForUpdates: true));
  }

  Future<Null> scrapePostPageInfo(
      PageInfo pi, Match m, String s, Document doc) async {
      final AnchorElement a = document.querySelector("span#react-root section main div div article header div div div a");
      pi.artist = a?.title;
//    final MetaElement ele = document.querySelector("meta[name=\"description\"]");
//    final String description = ele.content;
//    final Match m = _metaUserRegexp.firstMatch(description);
//    if(m==null)
//      throw new Exception("No match found for username in description meta tag.");
    //pi.artist = m[1];
  }

  Future<Null> scrapeUserPageInfo(
      PageInfo pi, Match m, String s, Document doc) async {
    final MetaElement ele = document.querySelector("meta[property=\"og:title\"]");
    final String description = ele.content;
    final Match m = _metaUserRegexp.firstMatch(description);
    if(m==null)
      throw new Exception("No match found for username in og:title meta tag.");
    pi.artist = m[1];
  }

//  handleLoadMoreButton: function() {
//    let eles = document.querySelectorAll("main article div a");
//    for(let i = 0; i< eles.length; i++) {
//      let ele = eles[i];
//      if(ele.innerText==="Load more") {
//        ele.click();
//        return true;
//      }
//    }
//    return false;
//  },
}
