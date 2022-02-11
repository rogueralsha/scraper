import 'dart:async';
import 'dart:html';
import 'package:logging/logging.dart';
import 'package:scraper/sources/a_source.dart';
import 'package:scraper/sources/src/typedefs.dart';

import '../../results/link_info.dart';
import 'i_criteria.dart';

class ManualUrlScraperCriteria implements ACriteria {
  static final Logger _log = new Logger("ManualUrlScraperCriteria");
  final LinkInfoScraper linkInfoScraper;

  ManualUrlScraperCriteria(this.linkInfoScraper);

  @override
  Future<void> applyCriteria(ASource source, String url, Document doc ) async {
    await this.linkInfoScraper(url, doc);
  }


}
