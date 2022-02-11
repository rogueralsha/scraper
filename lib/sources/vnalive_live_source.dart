import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class VNALiveSource extends ASource {
  static final Logger _log = new Logger("VNALiveSource");

  @override
  String get sourceName => "vna_live";

  static final RegExp _contentRegexp = new RegExp(
      r"^https?://.+\.vnalive\.com/members/vettenation/content.php.+",
      caseSensitive: false);

  VNALiveSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(this, _contentRegexp,
        [new SimpleUrlScraperCriteria(LinkType.video, "video#player_html5_api source")]));
  }

}
