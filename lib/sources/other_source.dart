import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class OtherSource extends ASource {
  static final Logger _log = new Logger("OtherSource");

  @override
  String get sourceName => "other";

  static final RegExp _regExp = new RegExp(
      r"^https?://((.+\.)?.+\..+)/.+$",
      caseSensitive: false);

  static final RegExp _imageExtensionRegExp = new RegExp(
      r"(jpg|jpeg|gif|webp|png|jfif)",
      caseSensitive: false);
  static final RegExp _videoExtensionRegExp = new RegExp(
      r"(webm|mp4|mkv|avi|mov|m4v)",
      caseSensitive: false);



  OtherSource(SettingsService settings) : super(settings) {
    this.urlScrapers.add(new SimpleUrlScraper(
          this,
          _regExp,
          [
            new SimpleUrlScraperCriteria(LinkType.video, "video"),
            new SimpleUrlScraperCriteria(LinkType.image, "img"),
            new SimpleUrlScraperCriteria(LinkType.image, "a", thumbnailSubSelector: "img", validateLinkInfo: validateImageLink),
            new SimpleUrlScraperCriteria(LinkType.video, "a", thumbnailSubSelector: "img", validateLinkInfo: validateVideoLink),
          ], urlRegexGroup: 1));
  }

  bool validateImageLink(LinkInfo link, Element ele) =>
      _imageExtensionRegExp.hasMatch(link.url);
  bool validateVideoLink(LinkInfo link, Element ele) =>
      _videoExtensionRegExp.hasMatch(link.url);

}
