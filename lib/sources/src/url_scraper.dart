import 'typedefs.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'dart:html';
import '../../results/page_info.dart';

class UrlScraper {
  static final Logger _log = new Logger("UrlScraper");
  final RegExp urlRegExp;
  PageInfoScraper pageInfoScraper;
  LinkInfoScraper linkInfoScraper;
  final bool useForEvaluation;

  UrlScraper(this.urlRegExp, this.pageInfoScraper, this.linkInfoScraper,
      {this.useForEvaluation = false});

  bool isMatch(String url) {
    _log.finest("Checking url $url against regex $urlRegExp");
    final bool result = urlRegExp.hasMatch(url);
    _log.fine("Result: $result");
    return result;
  }

  Future<Null> scrapePageInfo(
          PageInfo pageInfo, String url, Document document) =>
      this.pageInfoScraper(pageInfo, urlRegExp.firstMatch(url), url, document);

  Future<Null> startLinkInfoScraping(String url, Document document) async {
    await this.linkInfoScraper(url, document);
  }
}
