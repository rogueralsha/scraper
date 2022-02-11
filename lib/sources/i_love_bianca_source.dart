import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class ILoveBiancaSource extends ASource {
  static final Logger _log = new Logger("ILoveBiancaSource");

  @override
  String get sourceName => "i_love_bianca";

  static final RegExp _categories = new RegExp(
      r"^https?://www\.ilovebianca\.com/biancabeauchamp/category/.+$",
      caseSensitive: false);

  static final RegExp _galleries = new RegExp(
      r"^https?://www\.ilovebianca\.com/biancabeauchamp/[^/]+\-galleries/$",
      caseSensitive: false);

  static final RegExp _galleryRegExp = new RegExp(
      r"^https?://www\.ilovebianca\.com/biancabeauchamp/members/[^/]+/galleries[^/]+/[^/]+/$",
      caseSensitive: false);

  static final RegExp _videoRegExp = new RegExp(
      r"^https?://www\.ilovebianca\.com/biancabeauchamp/members/[^/]+/videos[^/]+/[^/]+/$",
      caseSensitive: false);
  ILoveBiancaSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(this, _categories, <SimpleUrlScraperCriteria>[
        new SimpleUrlScraperCriteria(
            LinkType.page, "div.post-image a"),
        new SimpleUrlScraperCriteria(LinkType.page, "div.navigation a.next"),
      ]))
      ..add(new SimpleUrlScraper(this, _galleryRegExp, <SimpleUrlScraperCriteria>[
        new SimpleUrlScraperCriteria(
            LinkType.file, "a.gallerytozip", contentDispositionFileName: true),
      ]))
      ..add(new SimpleUrlScraper(this, _videoRegExp, <SimpleUrlScraperCriteria>[
        new SimpleUrlScraperCriteria(
            LinkType.video, ".kgvid_meta_icons a"),
      ]));
  }


}
