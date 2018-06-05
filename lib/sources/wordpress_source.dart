import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class WordpressSource extends ASource {
  static final Logger _log = new Logger("WordpressSource");

  static final RegExp _contentRegExp = new RegExp(
      r"^(https?://([^/]+)/wp-content/uploads/\d{4}/\d{2}/(.+))-\d+x\d+(\.[^/]+)$",
      caseSensitive: false);

  WordpressSource(SettingsService settings) : super(settings) {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.file, _contentRegExp));

    this.urlScrapers.add(new SimpleUrlScraper(
        this,
        siteRegexp,
        [
          new SimpleUrlScraperCriteria(LinkType.page, "div.gallery a",
              validateLinkInfo: (LinkInfo li, Element ele) {
            if (_contentRegExp.hasMatch(li.thumbnail)) {
              final Match m = _contentRegExp.firstMatch(li.thumbnail);
              li
                ..url = "${m[1]}${m[4]}"
                ..filename = "${m[3]}${m[4]}"
                ..type = LinkType.image;
            }
            return true;
          })
        ],
        saveByDefault: false));
  }

  @override
  bool canScrapePage(String url,
      {Document document, bool forEvaluation = false}) {
    _log.finest("canScrapePage");

    if (document == null) return false;

    final MetaElement metaGenerator =
        document.querySelector('meta[name="generator"]');

    return metaGenerator?.content?.toLowerCase()?.contains("wordpress") ??
        false;
  }
}
