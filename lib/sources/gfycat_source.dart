import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class GfycatSource extends ASource {
  static final Logger _log = new Logger("GfycatSource");

  @override
  String get sourceName => "gfycat";

  static final RegExp _regExp = new RegExp(
      r"^https?://(www\.)?gfycat\.com/([^/?]+)(\?[^/]+)?$",
      caseSensitive: false);
  static final RegExp _albumRegexp = new RegExp(
      r"^https?://(www\.)?gfycat\.com/@([^/]+)/collections/[^/]+/[^/]+$",
      caseSensitive: false);


  static final RegExp _albumDetailRegexp = new RegExp(
      r"^https?://(www\.)?gfycat\.com/(%40[^/]+)/[^/]+/detail/([^/]+)$",
      caseSensitive: false);

  static final RegExp _detailRegexp = new RegExp(
      r"^https?://(www\.)?gfycat\.com/gifs/detail/([^/]+)$",
      caseSensitive: false);

  static final RegExp directRegExp = new RegExp(
      r"^https?://giant\.gfycat\.com/([^/.]+)\.(webm|mp4)$",
      caseSensitive: false);

  static final RegExp deliveryRegExp = new RegExp(
      r"^https?://(www\.)?gifdeliverynetwork\.com/([^/.]+)$",
      caseSensitive: false);

  GfycatSource(SettingsService settings) : super(settings) {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.video, directRegExp));

    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _albumRegexp,
        [
          new SimpleUrlScraperCriteria(LinkType.page, "div.album-container div.m-grid-item  a",
              validateLinkInfo: (LinkInfo li, Element e) {
                if (_albumDetailRegexp.hasMatch(li.url)) {
                  final String name = _albumDetailRegexp.firstMatch(li.url)[3];
                  li.url = "https://gfycat.com/$name";
                }
                if (_detailRegexp.hasMatch(li.url)) {
                  final String name = _detailRegexp.firstMatch(li.url)[2];
                  li.url = "https://gfycat.com/$name";
                }

            return true;
          })
        ],
        saveByDefault: false, urlRegexGroup: 2));

    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _regExp,
        [
          new SimpleUrlScraperCriteria(
              LinkType.video, "source[type=\"video/mp4\"]", validateLinkInfo:validateLinkInfo )
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
    if (regExp == directRegExp) {
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
        directRegExp.firstMatch(url)?.group(1);
    if (name != null) {
      return "https://thumbs.gfycat.com/$name-poster.jpg";
    }
    return null;
  }
}
