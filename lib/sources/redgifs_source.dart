import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';
import 'gfycat_source.dart';

class RedgifsSource extends ASource {
  static final Logger _log = new Logger("RedgifsSource");

  @override
  String get sourceName => "redgifs";

  static final RegExp _regExp = new RegExp(
      r"^https?://(www\.)?redgifs\.com/watch/(.+)$",
      caseSensitive: false);

  RedgifsSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _regExp,
        [
          new SimpleUrlScraperCriteria(
              LinkType.video, "meta[property=\"og:video\"]", validateLinkInfo:validateLinkInfo )
        ],
        saveByDefault: false,
        urlRegexGroup: 2,
        useForEvaluation: true));
  }

  bool validateLinkInfo(LinkInfo link, Element ele) {
    if(link.url.endsWith("-mobile.mp4")) {
      return false;
    }
    return true;
  }

//  @override
//  Future<LinkInfo> evaluateLinkImpl(String link, String sourceUrl) async {
//    _log.finest('evaluateLinkImpl($link, $sourceUrl)');
//    if (_regExp.hasMatch(link)) {
//      _log.finest("Link matches gfycat post regexp");
//      final Match m = _regExp.firstMatch(link);
//      final String name = m[2];
//      _log.finest("Gfycat name: ${m[2]}");
//      final int capitalCount = name.replaceAll(notCapitalRegexp,"").length;
//      // gfycat direct links are case sensitive. All gfycat links are made of 3 words, so we check for 3 capital letters.
//      // If not, then we just let it open as a page so it can redirect us to the file properly.
//      if(capitalCount==3) {
//        _log.finest("3 capital letters found, transalating to direct link");
//        final String newUrl = generateDirectLink(name);
//        final LinkInfo output = new LinkInfoImpl(newUrl, sourceUrl,
//            thumbnail: determineThumbnail(newUrl),
//            type: LinkType.video,
//            filename: "$name.webm");
//        return output;
//      } else {
//        _log.finest("$capitalCount capital letters found, not transalating to direct link");
//      }
//    }
//
//    return super.evaluateLinkImpl(link, sourceUrl);
//  }

  @override
  LinkInfo reEvaluateLink(LinkInfo li, RegExp regExp) {
    if (regExp == GfycatSource.directRegExp) {
      if (li.url?.toLowerCase()?.endsWith(".mp4")??false) {
        li.url = "${li.url.substring(0,li.url.length-4)}.webm";
      }
    }
    return li;
  }
//
//  String generateDirectLink(String name) =>
//      "https://giant.gfycat.com/$name.webm";

  @override
  String determineThumbnail(String url) {
    final String name = _regExp.firstMatch(url)?.group(2) ??
        GfycatSource.directRegExp.firstMatch(url)?.group(1);
    if (name != null) {
      return "https://thumbs.gfycat.com/$name-poster.jpg";
    }
    return null;
  }
}
