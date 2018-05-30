import 'dart:async';
import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'src/simple_url_scraper.dart';
import 'package:scraper/globals.dart';

class GfycatSource extends ASource {
  static final Logger _log = new Logger("GfycatSource");

  static final RegExp _regExp = new RegExp(
      r"https?://(www\.)?gfycat\.com/([^/]+)$",
      caseSensitive: false);
  static final RegExp _albumRegexp = new RegExp(
      r"https?://(www\.)?gfycat\.com/@([^/]+)/[^/]+$",
      caseSensitive: false);
  static final RegExp _albumDetailRegexp = new RegExp(
      r"https?://(www\.)?gfycat\.com/(%40[^/]+)/[^/]+/detail/([^/]+)$",
      caseSensitive: false);
  static final RegExp _directRegExp = new RegExp(
      r"https?://giant\.gfycat\.com/([^/.]+)\.(webm|mp4)$",
      caseSensitive: false);

  GfycatSource() {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.video, _directRegExp));

    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _albumRegexp,
        [
          new SimpleUrlScraperCriteria(LinkType.page, "div.deckgrid  a",
              validateLinkInfo: (LinkInfo li, Element e) {
            if (_albumDetailRegexp.hasMatch(li.url)) {
              final String name = _albumDetailRegexp.firstMatch(li.url)[3];
              li.url = "https://gfycat.com/$name";
            }
            return true;
          })
        ],
        saveByDefault: false));

    this.urlScrapers.add(new SimpleUrlScraper(this, _regExp,
        [new SimpleUrlScraperCriteria(LinkType.video, "source#webmSource")],
        saveByDefault: false, urlRegexGroup: 2, useForEvaluation: true));
  }

  @override
  Future<LinkInfo> evaluateLinkImpl(String link, String sourceUrl) async {
    _log.finest('evaluateLinkImpl($link, $sourceUrl)');
    if (_regExp.hasMatch(link)) {
      _log.finest("Link matches gfycat post regexp");
      final Match m = _regExp.firstMatch(link);
      final String name = m[2];
      _log.finest("Gfycat name: ${m[2]}");
      final int capitalCount = name.replaceAll(notCapitalRegexp,"").length;
      // gfycat direct links are case sensitive. All gfycat links are made of 3 words, so we check for 3 capital letters.
      // If not, then we just let it open as a page so it can redirect us to the file properly.
      if(capitalCount==3) {
        _log.finest("3 capital letters found, transalating to direct link");
        final String newUrl = generateDirectLink(name);
        final LinkInfo output = new LinkInfoImpl(newUrl, sourceUrl,
            thumbnail: determineThumbnail(newUrl),
            type: LinkType.video,
            filename: "$name.webm");
        return output;
      } else {
        _log.finest("$capitalCount capital letters found, not transalating to direct link");
      }
    }

    return super.evaluateLinkImpl(link, sourceUrl);
  }

  @override
  LinkInfo reEvaluateLink(LinkInfo li, RegExp regExp) {
    if (regExp == _directRegExp) {
      if (li.url.toLowerCase().endsWith(".mp4")) {
        li.url = "${li.url.substring(0,li.url.length-4)}.webm";
      }
    }
    return li;
  }

  String generateDirectLink(String name) =>
      "https://giant.gfycat.com/$name.webm";

  @override
  String determineThumbnail(String url) {
    final String name = _regExp.firstMatch(url)?.group(2) ??
        _directRegExp.firstMatch(url)?.group(1);
    if (name != null) {
      return "https://thumbs.gfycat.com/$name-poster.jpg";
    }
    return null;
  }
}
