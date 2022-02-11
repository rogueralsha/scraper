import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class FightersGenerationSource extends ASource {
  static final Logger logImpl = new Logger("FightersGenerationSource");

  @override
  String get sourceName => "fighers_generation";

  static final RegExp _galleryRegexp = new RegExp(
      r"^https?://www\.fightersgeneration\.com/characters[^/]*/([^\-]+)(-.+)?.html?",
      caseSensitive: false);
  static final RegExp _imageRegexp = new RegExp(
      r"\.(png|jpeg|jpg|webp|bmp|gif|psd|xcf|tif|tiff|eps)$",
      caseSensitive: false);


  FightersGenerationSource(SettingsService settings) : super(settings) {
    //
    this
      .urlScrapers.add(new SimpleUrlScraper(this, _galleryRegexp,
          [
            new SimpleUrlScraperCriteria(LinkType.image, "img"),
            new SimpleUrlScraperCriteria(LinkType.file, "a",
                validateLinkInfo: (li, e) =>
                  (!li.url.endsWith(".html"))
                      && (!li.url.endsWith(".htm"))
                      && (!li.url.endsWith(".com/"))
                ),
          ]))
        ;
  }



}
