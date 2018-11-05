import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class WebmShareSource extends ASource {
  static final Logger _log = new Logger("WebmShareSource");

  static final RegExp _regExp = new RegExp(
      r"https?://webmshare\.com/(play/)?([^/]+)$",
      caseSensitive: false);

  WebmShareSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        _regExp,
        [
          new SimpleUrlScraperCriteria(
              LinkType.page, "video#player source[type='video/webm']")
        ],
        urlRegexGroup: 2,
        useForEvaluation: true));
  }

  @override
  String determineThumbnail(String url) {
    final Match m = _regExp.firstMatch(url);
    if (m != null) {
      return "https://s1.webmshare.com/t/${m[2]}.jpg";
    }
    return null;
  }
}
