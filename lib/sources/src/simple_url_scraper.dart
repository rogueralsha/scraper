import 'typedefs.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'dart:html';
import '../../results/page_info.dart';
import 'url_scraper.dart';
import '../a_source.dart';
import 'simple_url_scraper_criteria.dart';
import 'i_criteria.dart';
export 'simple_url_scraper_criteria.dart';
export 'manual_url_scraper_criteria.dart';
export 'url_scraper.dart';


class SimpleUrlScraper extends UrlScraper {
  static final Logger _log = new Logger("SimpleUrlScraper");
  final ASource _source;
  final List<ACriteria> criteria;
  final bool saveByDefault;
  final bool watchForUpdates;
  final int urlRegexGroup;
  final bool incrementalLoader;
  final PageInfoScraper customPageInfoScraper;
  final String setNameSelector;

  SimpleUrlScraper(this._source, RegExp urlRegexp, this.criteria,
      {this.customPageInfoScraper,
      this.saveByDefault = true,
      this.watchForUpdates = false,
      this.urlRegexGroup = 1,
      bool useForEvaluation = false,
      this.incrementalLoader,
      this.setNameSelector})
      : super(urlRegexp, null, null, useForEvaluation: useForEvaluation) {
    this.pageInfoScraper = _pageInfoScraperImpl;
    this.linkInfoScraper = _linkInfoScraperImpl;
  }

  Future<Null> _pageInfoScraperImpl(
      PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.info("_pageInfoScraperImpl");
    pageInfo.saveByDefault = this.saveByDefault;
    if (customPageInfoScraper == null) {
      await _source.artistFromRegExpPageScraper(pageInfo, m, url, doc,
          group: urlRegexGroup);
    } else {
      await customPageInfoScraper(pageInfo, m, url, doc);
    }
    if(this.setNameSelector?.isNotEmpty??false){
      final Element element = doc.querySelector(this.setNameSelector);
      final String setName = element?.text;
      pageInfo.setName = setName;
    }
    pageInfo.incrementalLoader = this.incrementalLoader;
  }

  MutationObserver _observer;

  Future<Null> _linkInfoScraperImpl(String url, Document document) async {
    await _scrapeForLinks(url, document);

    if (watchForUpdates) {
      if (_observer == null) {
        _observer = new MutationObserver(
            (List<MutationRecord> mutations, MutationObserver observer) {
          for (MutationRecord mutation in mutations) {
            if (mutation.type != "childList" ||
                mutation.addedNodes.length == 0) {
              continue;
            }
            for (int j = 0; j < mutation.addedNodes.length; j++) {
              Node node = mutation.addedNodes[j];
              _scrapeForLinks(url, node);
            }
            break;
          }
          _source.sendScrapeDone();
        });
        _observer.observe(document, childList: true, subtree: true);
      }
    }
  }

  Future<Null> _scrapeForLinks(String url, Document doc) async {
    _log.finest("_scrapeForLinks($url, $doc) start");
    for (ACriteria criteria in this.criteria) {
      await criteria.applyCriteria(this._source, url, doc);
    }
  }
}
