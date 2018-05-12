import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'src/simple_url_scraper.dart';

class GfycatSource extends ASource {
  static final Logger logImpl = new Logger("GfycatSource");

  static final RegExp _regExp= new RegExp("https?:\\/\\/gfycat\.com\\/([^\\/]+)\$", caseSensitive: false);
  static final RegExp _albumRegexp= new RegExp("https?:\\/\\/gfycat\.com\\/@([^\\/]+)\\/[^\\/]+\$", caseSensitive: false);

  static final RegExp _albumDetailRegexp= new RegExp("https?:\\/\\/gfycat\.com\\/(%40[^\\/]+)\\/[^\\/]+\\/detail\\/([^\\/]+)\$", caseSensitive: false);

  GfycatSource() {
    this.urlScrapers.add(new SimpleUrlScraper(this, _albumRegexp,
        [new SimpleUrlScraperCriteria(LinkType.page, "div.deckgrid  a", validateLinkInfo: (LinkInfo li, Element e) {
          if(_albumDetailRegexp.hasMatch(li.url)) {
            String name = _albumDetailRegexp.firstMatch(li.url)[2];
            li.url = "https://gfycat.com/$name";
          }
          return true;
        })], saveByDefault: false));


    this.urlScrapers.add(new SimpleUrlScraper(this, _regExp, [
          new SimpleUrlScraperCriteria(LinkType.video, "source#webmSource")
        ], saveByDefault: false));
  }

  @override
  String determineThumbnail(String url) {
    if (_regExp.hasMatch(url)) {
      Match result = _regExp.firstMatch(url);
      return "https://thumbs.gfycat.com/${result[1]}-poster.jpg";
    }
    return null;
  }
}
