import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class IbradomeSource extends ASource {
  static final Logger logImpl = new Logger("IbradomeSource");

  @override
  String get sourceName => "ibradome";

  static final RegExp _galleryRegexp = new RegExp(
      r"^https?://ibradome\.com/gallery/\d+",
      caseSensitive: false);


  IbradomeSource(SettingsService settings) : super(settings) {
    //
    this
      .urlScrapers.add(new SimpleUrlScraper(this, _galleryRegexp,
          [
            new SimpleUrlScraperCriteria(LinkType.image, "figure.vis a"),
          ]))
        ;
  }



}
