import 'dart:html';
import 'a_source.dart';
import 'artstation_source.dart';
import 'blogger_source.dart';
import 'comic_art_community_source.dart';
import 'comic_art_fans_source.dart';
import 'deviantart_source.dart';
import 'etc_source.dart';
import 'facebook_source.dart';
import 'gfycat_source.dart';
import 'hentai_foundry_source.dart';
import 'imgur_source.dart';
import 'instagram_source.dart';
import 'reddit_source.dart';
import 'shimmie_source.dart';
import 'tumblr_source.dart';
import 'twitter_source.dart';
import 'tiny_tiny_rss_source.dart';
import 'package:logging/logging.dart';
export 'a_source.dart';


final Logger _log = new Logger("sources.dart");

final List<ASource> sourceInstances = <ASource>[
  new DeviantArtSource(),
  new RedditSource(),
  new ArtStationSource(),
  new ComicArtCommunitySource(),
  new ComicArtFansSource(),
  new ShimmieSource(),
  new HentaiFoundrySource(),
  new InstagramSource(),
  new ImgurSource(),
  new GfycatSource(),
  new BloggerSource(),
  new TumblrSource(),
  new TwitterSource(),
  new FacebookSource(),
  new EtcSource(),
  new TinyTinyRSSSource()
];

ASource getScraperForSite(String url, Document document) {
  for (ASource source in sourceInstances) {
    _log.finest("Checking if $source can scrape source");
    if (source.canScrapePage(url, document: document)) {
      _log.finest("It can!");
      return source;
    }
  }
  return null;
}