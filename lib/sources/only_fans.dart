import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class OnlyFansSource extends ASource {
  static final Logger _log = new Logger("OnlyFansSource");

  @override
  String get sourceName => "only_fans";



  static final RegExp _userRegExp = new RegExp(
      r"^https?://onlyfans\.com/([^/]+)$",
      caseSensitive: false);

  static final RegExp _postRegExp = new RegExp(
      r"^https?://onlyfans\.com/(\d+)/([^/]+)$",
      caseSensitive: false);

  OnlyFansSource(SettingsService settings) : super(settings) {
    this.urlScrapers
      ..add(new UrlScraper(
          _userRegExp, super.artistFromRegExpPageScraper, scrapeUser))
    ..add(new UrlScraper(
          _postRegExp, this.artistFromRegExpPageScraper, scrapePost));
  }

  @override
  Future<Null> artistFromRegExpPageScraper(
      PageInfo pageInfo, Match m, String url, Document doc,
      {int group = 2})  =>
        super.artistFromRegExpPageScraper(pageInfo, m, url, doc, group: group);

  final Map<String,String> _customHeaders = {
    "app-token": "33d57ade8c02dbc5a333db99ff9ae26a",
    "accept": "application/json, text/plain, */*",
    "sign": "14:aa01cc823d65415d1160045e31be7132f941708a:ac0:609ebeb2",
    "user-id": "13905001",
    "x-bc": "b5afd0e13869961c5b2cf96c898381f6b24da09c",
  };

  Map<String,String> getCustomHeaders() {
    final Map<String,String> output = new Map<String,String>();
    output.addAll(_customHeaders);
    output["time"] = DateTime.now().millisecondsSinceEpoch.toString();
    return output;
  }


  Future<Map<String,dynamic>> getUserData(String username) {
    String dataUrl = "https://onlyfans.com/api2/v2/users/$username";

    return fetchJsonData(dataUrl,
        customHeaders: getCustomHeaders());
  }

  Future<Null> scrapeUser(String url, Document doc) async  {
    _log.finest("scrapeUser(String url, Document doc)");
    final Match m = _userRegExp.firstMatch(url);
    final String artist = m.group(1);

    final Map<String,dynamic> artistData = await getUserData(artist);

    String dataUrl = "https://onlyfans.com/api2/v2/users/${artistData['id']}/posts?limit=10&order=publish_date_desc&skip_users=all&skip_users_dups=1&pinned=0&format=infinite";


    // ignore: literal_only_boolean_expressions
    while(true) {
      _log.finest("scrapeUser loop start");

      final Map<String,dynamic> jsonData = await fetchJsonData(dataUrl,
          customHeaders: getCustomHeaders());

      final List<Map> posts = jsonData["list"];

      String lastPostDate;
      for(Map post in posts) {
        final List<Map> medias = post["media"];

        for(Map media in medias) {
          processMediaObject(url, media);
        }

        lastPostDate = post["postedAtPrecise"];
      }


      if(jsonData==null || !jsonData.containsKey("hasMore") || !jsonData["hasMore"]) {
        _log.finest("scrapeUser loop break");
        break;
      } else {
        dataUrl = "https://onlyfans.com/api2/v2/users/${artistData['id']}/posts?limit=10&order=publish_date_desc&skip_users=all&skip_users_dups=1&pinned=0&format=infinite&beforePublishTime=$lastPostDate";
      }
      _log.finest("scrapeUser loop repeat");

    }



  }

  Future<Null> scrapePost(String url, Document doc) async {
    _log.finest("scrapePost(String url, Document doc)");
    final Match m = _postRegExp.firstMatch(url);
    final String id = m.group(1);
    final String artist = m.group(2);

    await scrapePostID(url, id);
  }

  Future<Null> scrapePostID(String url, String id) async {
    final String dataUrl = "https://onlyfans.com/api2/v2/posts/$id?skip_users=all&skip_users_dups=1";

    final Map<String,dynamic> jsonData = await fetchJsonData(dataUrl,
        customHeaders:  getCustomHeaders());
    final List<Map> medias = jsonData["media"];

    for(Map media in medias) {
      processMediaObject(url, media);
    }
  }

  void processMediaObject(String url, Map media) {
    switch(media["type"]) {
      case "photo":
        final String link = media["full"];
        final String thumb = media["preview"];
        if(link?.isNotEmpty??false) {
          createAndSendLinkInfo(
              link, url, type: LinkType.image, thumbnail: thumb);
        }
        break;
      case "video":
        final String link = media["full"];
        final String thumb = media["preview"];
        if(link?.isNotEmpty??false) {
          createAndSendLinkInfo(
              link, url, type: LinkType.video, thumbnail: thumb);
        }
        break;
    }
  }

}
