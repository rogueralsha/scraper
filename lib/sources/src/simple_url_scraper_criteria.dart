import 'dart:async';
import 'dart:html';
import 'package:logging/logging.dart';
import 'package:scraper/sources/a_source.dart';

import '../../results/link_info.dart';
import 'i_criteria.dart';

typedef bool ValidateLinkInfo(LinkInfo li, Element ele);

class SimpleUrlScraperCriteria implements ACriteria {
  static final Logger _log = new Logger("SimpleUrlScraperCriteria");

  final LinkType linkType;
  final String linkSelector;
  final String fallbackSelector;
  final String thumbnailSubSelector;
  final String linkAttribute;
  final ValidateLinkInfo validateLinkInfo;
  final int limit;
  final bool evaluateLinks;
  final bool contentDispositionFileName;
  final RegExp linkRegExp;
  SimpleUrlScraperCriteria(this.linkType, this.linkSelector,
      {this.thumbnailSubSelector = "img",
      this.validateLinkInfo,
      this.limit = -1,
      this.evaluateLinks = false,
      this.linkRegExp,
      this.fallbackSelector,
      this.linkAttribute,
      this.contentDispositionFileName});

  @override
  Future<void> applyCriteria(ASource source, String url, Document doc ) async {
    int total = 0;
    _log.finest("Querying with ${this.linkSelector}");
    ElementList<Element> eles =
    doc.querySelectorAll(this.linkSelector);
    _log.finest("${eles.length} elements found");
    if (eles.isEmpty && (this.fallbackSelector?.isNotEmpty ?? false)) {
      eles = doc.querySelectorAll(this.fallbackSelector);
    }

    for (Element ele in eles) {
      final LinkInfo li = source.createLinkFromElement(ele, url,
          thumbnailSubSelector: this.thumbnailSubSelector,
          defaultLinkType: this.linkType,
          linkAttribute: this.linkAttribute);

      if (li == null) continue;

      if (this.linkRegExp != null) {
        _log.finest(
            "linkRegExp (${this.linkRegExp}) specified, checking against url ${li.url}");
        if (!this.linkRegExp.hasMatch(li.url)) {
          _log.finest("Did not pass");
          continue;
        }
      }

      if(this.contentDispositionFileName) {
        try {
          li.filename = await source.getDispositionFilename(li.url);
        }  on Exception catch(e,st) {
          _log.warning("Error while fetching content disposition name", e, st);
        }
      }

      if (this.validateLinkInfo != null) {
        _log.finest("validateLinkInfo specified, testing");

        if (!this.validateLinkInfo(li, ele)) {
          _log.finest("Did not pass validation");
          continue;
        }
        _log.finest("Passed validation");
      }

      if (this.evaluateLinks) {
        await source.evaluateLink(li.url, url);
      } else {
        source.sendLinkInfo(li);
      }
      total++;
      if (this.limit > 0 && total >= this.limit) {
        _log.info(
            "At criteria limit (${this.limit}), skipping remaining elements");
        break;
      }
    }
  }


}
