import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class SexypattycakeSource extends ASource {
  static final Logger _log = new Logger("SexypattycakeSource");

  @override
  String get sourceName => "sexy_pattycake";

  static final RegExp _albumsRegexp = new RegExp(
      r"^https?://(www\.)?sexypattycake\.com/members/photo/index.html.+$",
      caseSensitive: false);

  static final RegExp _albumRegexp = new RegExp(
      r"^https?://(www\.)?sexypattycake\.com/members/gallery/\?directory.+$",
      caseSensitive: false);

  static final RegExp _imageRegexp = new RegExp(
      r"^https?://(www\.)?sexypattycake\.com/members/gallery/image.php.+$",
      caseSensitive: false);

  SexypattycakeSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new SimpleUrlScraper(this, _albumsRegexp,
          [new SimpleUrlScraperCriteria(LinkType.page, "div.updates > div.update > a",
              validateLinkInfo: (LinkInfo li, Element e) {
                li.pathSuffix = e.text;
                li.filename = e.text;
                return true;
          })]))
      ..add(new SimpleUrlScraper(this, _albumRegexp,
          [new SimpleUrlScraperCriteria(LinkType.page, "#photo-updates a")]))
      ..add(new SimpleUrlScraper(
          this,
          _imageRegexp,
          [
            new SimpleUrlScraperCriteria(LinkType.image, "div#content img")
          ]));
  }


}
