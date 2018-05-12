import 'typedefs.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'dart:html';
import '../../results/page_info.dart';
import 'url_scraper.dart';
import '../a_source.dart';
import 'simple_url_scraper_criteria.dart';
export 'simple_url_scraper_criteria.dart';

class SimpleUrlScraper extends UrlScraper {
  static final Logger _log = new Logger("SimpleUrlScraper");
  final ASource _source;
  final List<SimpleUrlScraperCriteria> criteria;
  final bool saveByDefault;

  SimpleUrlScraper(this._source, RegExp urlRegexp, this.criteria,
      {PageInfoScraper pif: null, this.saveByDefault: true})
      : super(urlRegexp, null, null) {
    this.pageInfoScraper = pif ?? _pageInfoScraperImpl;
    this.linkInfoScraper = _linkInfoScraperImpl;
  }

  Future<Null> _pageInfoScraperImpl(PageInfo pageInfo, Match m, String url, Document doc) async {
    _log.info("_pageInfoScraperImpl");
    await _source.artistFromRegExpPageScraper(pageInfo, m, url, doc);
    pageInfo.saveByDefault = this.saveByDefault;
  }



  Future<Null> _linkInfoScraperImpl(String url, Document document) async {
    int total = 0;
    _log.finest("_linkInfoScraperImpl($url, $document) start");
    for (SimpleUrlScraperCriteria criteria in this.criteria) {
      _log.finest("Querying with ${criteria.linkSelector}");
      ElementList eles = document.querySelectorAll(criteria.linkSelector);
      _log.finest("${eles.length} elements found");
      for (Element ele in eles) {
        String link;
        String thumbnail = null;
        if (ele is AnchorElement) {
          _log.finest("AnchorElement found");
          link = ele.href;
          if (criteria.thumbnailSubSelector?.isNotEmpty ?? false) {
            _log.finest("Querying with ${criteria.thumbnailSubSelector}");
            Element thumbEle = ele.querySelector(criteria.thumbnailSubSelector);
            if (thumbEle != null) {
              _log.info("Thumbnail element found");
              if (thumbEle is AnchorElement) {
                _log.finest("AnchorElement found for thumbnail");
                thumbnail = thumbEle.href;
              } else if (thumbEle is ImageElement) {
                _log.finest("ImageElement found for thumbnail");
                thumbnail = thumbEle.src;
              } else {
                _log.info("Unsupported element found for thumbnail, skipping");
              }
            } else {
              _log.finest("Thumbnail element not found");
            }
          }
        } else if (ele is ImageElement) {
          _log.finest("ImageElement found");
          link = ele.src;
        } else if(ele is EmbedElement) {
          _log.finest("EmbedElement found");
          link = ele.src;
        } else if(ele is VideoElement) {
          _log.finest("VideoElement found");
          link = ele.src;
          if (ele.poster?.isNotEmpty ?? false) {
            _log.info("Poster attribute found, using as thumnail");
            thumbnail = ele.poster;
          }
        } else if(ele is SourceElement) {
          _log.finest("SourceElement found");
          link = ele.src;
          if(ele.parent is VideoElement) {
            _log.finest("Parent element is video, checking for poster");
            VideoElement parentEle = ele.parent;
            if (parentEle.poster?.isNotEmpty ?? false) {
              _log.info("Poster attribute found, using as thumnail");
              thumbnail = parentEle.poster;
            }
          }
        } else {
          _log.info("Unsupported element $ele found, skipping");
          continue;
        }
        LinkInfo li = new LinkInfoImpl(link, url,
            type: criteria.linkType, thumbnail: thumbnail);

        if (criteria.validateLinkInfo != null) {
          _log.finest("validateLinkInfo specified, testing");

          if (!criteria.validateLinkInfo(li, ele)) {
            _log.finest("Did not pass validation");
            continue;
          }
          _log.finest("Passed validation");
        }

        _source.sendLinkInfo(li);
        total++;
        if(criteria.limit>0&&total>=criteria.limit) {
          _log.info("At criteria limit (${criteria.limit}), skipping remaining elements");
          break;
        }
      }
    }
  }
}
