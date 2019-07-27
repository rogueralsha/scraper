import 'typedefs.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'dart:html';
import '../../results/page_info.dart';
import 'url_scraper.dart';
import '../a_source.dart';
import 'simple_url_scraper_criteria.dart';
export 'simple_url_scraper_criteria.dart';
export 'url_scraper.dart';

class SimpleUrlScraper extends UrlScraper {
  static final Logger _log = new Logger("SimpleUrlScraper");
  final ASource _source;
  final List<SimpleUrlScraperCriteria> criteria;
  final bool saveByDefault;
  final bool watchForUpdates;
  final int urlRegexGroup;
  final bool incrementalLoader;
  final PageInfoScraper customPageInfoScraper;

  SimpleUrlScraper(this._source, RegExp urlRegexp, this.criteria,
      {this.customPageInfoScraper,
      this.saveByDefault = true,
      this.watchForUpdates = false,
      this.urlRegexGroup = 1,
      bool useForEvaluation = false,
      this.incrementalLoader})
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
    pageInfo.incrementalLoader = this.incrementalLoader;
  }

  MutationObserver _observer;

  Future<Null> _linkInfoScraperImpl(String url, Document document) async {
    await _scrapeForLinks(url, document.documentElement);

    if (watchForUpdates) {
      if (_observer == null) {
        _observer = new MutationObserver(
            (List<dynamic> mutations, MutationObserver observer) {
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

  Future<Null> _scrapeForLinks(String url, Element element) async {
    int total = 0;

    _log.finest("_linkInfoScraperImpl($url, $element) start");
    for (SimpleUrlScraperCriteria criteria in this.criteria) {
      _log.finest("Querying with ${criteria.linkSelector}");
      ElementList<Element> eles =
          element.querySelectorAll(criteria.linkSelector);
      _log.finest("${eles.length} elements found");
      if (eles.isEmpty && (criteria.fallbackSelector?.isNotEmpty ?? false)) {
        eles = element.querySelectorAll(criteria.fallbackSelector);
      }

      for (Element ele in eles) {
        final LinkInfo li = _source.createLinkFromElement(ele, url,
            thumbnailSubSelector: criteria.thumbnailSubSelector,
            defaultLinkType: criteria.linkType,
        linkAttribute: criteria.linkAttribute);

        if (li == null) continue;

        if (criteria.linkRegExp != null) {
          _log.finest(
              "linkRegExp (${criteria.linkRegExp}) specified, checking against url ${li.url}");
          if (!criteria.linkRegExp.hasMatch(li.url)) {
            _log.finest("Did not pass");
            continue;
          }
        }

        if (criteria.validateLinkInfo != null) {
          _log.finest("validateLinkInfo specified, testing");

          if (!criteria.validateLinkInfo(li, ele)) {
            _log.finest("Did not pass validation");
            continue;
          }
          _log.finest("Passed validation");
        }

        if (criteria.evaluateLinks) {
          await _source.evaluateLink(li.url, url);
        } else {
          _source.sendLinkInfo(li);
        }
        total++;
        if (criteria.limit > 0 && total >= criteria.limit) {
          _log.info(
              "At criteria limit (${criteria.limit}), skipping remaining elements");
          break;
        }
      }
    }
  }
}
