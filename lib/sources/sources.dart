import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'a_source.dart';
import 'artstation_source.dart';
import 'blogger_source.dart';
import 'comic_art_community_source.dart';
import 'comic_art_fans_source.dart';
import 'deviantart_source.dart';
import 'erome_source.dart';
import 'etc_source.dart';
import 'facebook_source.dart';
import 'gfycat_source.dart';
import 'hentai_foundry_source.dart';
import 'image_fap_source.dart';
import 'imgur_source.dart';
import 'instagram_source.dart';
import 'minitokyo_source.dart';
import 'patreon_source.dart';
import 'pinupfiles_source.dart';
import 'reddit_source.dart';
import 'shimmie_source.dart';
import 'tiny_tiny_rss_source.dart';
import 'tumblr_source.dart';
import 'twitter_source.dart';
import 'webmshare_source.dart';
import 'wordpress_source.dart';
import 'newgrounds_source.dart';
import 'thothub_source.dart';
import 'dartlery_source.dart';
import 'sports_illustrated_source.dart';

export 'a_source.dart';
import 'vnalive_live_source.dart';

const List<dynamic> sourceProviders = const <dynamic>[
  const ClassProvider(DeviantArtSource),
  const ClassProvider(RedditSource),
  const ClassProvider(ArtStationSource),
  const ClassProvider(ComicArtCommunitySource),
  const ClassProvider(ComicArtFansSource),
  const ClassProvider(ShimmieSource),
  const ClassProvider(HentaiFoundrySource),
  const ClassProvider(InstagramSource),
  const ClassProvider(ImgurSource),
  const ClassProvider(ImageFapSource),
  const ClassProvider(GfycatSource),
  const ClassProvider(BloggerSource),
  const ClassProvider(TumblrSource),
  const ClassProvider(TwitterSource),
  const ClassProvider(FacebookSource),
  const ClassProvider(EtcSource),
  const ClassProvider(TinyTinyRSSSource),
  const ClassProvider(EromeSource),
  const ClassProvider(PatreonSource),
  const ClassProvider(WordpressSource),
  const ClassProvider(WebmShareSource),
  const ClassProvider(PinupfilesSource),
  const ClassProvider(NewgroundsSource),
  const ClassProvider(VNALiveSource),
  const ClassProvider(MinitokyoSource),
  const ClassProvider(SportsIllustratedSource),
  const ClassProvider(ThothubSource),
  const ClassProvider(DartlerySource),
];

class Sources {
  static final List<ASource> sourceInstances = <ASource>[];

  final Logger _log = new Logger("Scraper");

  Sources(
      DeviantArtSource deviantArtSource,
      RedditSource redditSource,
      ArtStationSource artstationSource,
      ComicArtCommunitySource comicArtCommunity,
      ComicArtFansSource comicartFanSource,
      ShimmieSource shimmieSource,
      HentaiFoundrySource hentaiFoundrySource,
      InstagramSource instagramSource,
      ImageFapSource imageFapSource,
      ImgurSource imgurSource,
      GfycatSource gfycatSource,
      BloggerSource bloggerSource,
      TumblrSource tumblrSource,
      TwitterSource twitterSource,
      FacebookSource facebookSource,
      EtcSource etcSource,
      TinyTinyRSSSource ttRssSource,
      EromeSource eromeSource,
      PatreonSource patreonSource,
      WordpressSource wordpressSource,
      PinupfilesSource pinupfilesSource,
      WebmShareSource webmShareSource,
      NewgroundsSource newgroundsSource,
      VNALiveSource vnaLiveSource,
      MinitokyoSource minitokyoSource,
      SportsIllustratedSource sportsIllustratedSource,
      ThothubSource thothubSource,
      DartlerySource dartlerySource) {
    sourceInstances.addAll([
      etcSource,
      deviantArtSource,
      redditSource,
      artstationSource,
      comicArtCommunity,
      comicartFanSource,
      hentaiFoundrySource,
      instagramSource,
      imgurSource,
      imageFapSource,
      gfycatSource,
      tumblrSource,
      twitterSource,
      facebookSource,
      eromeSource,
      patreonSource,
      webmShareSource,
      pinupfilesSource,
      newgroundsSource,
      minitokyoSource,
      vnaLiveSource,
      sportsIllustratedSource,
      thothubSource,
      // These are generic source, keep at the bottom
      bloggerSource,
      ttRssSource,
      shimmieSource,
      wordpressSource,
      dartlerySource
    ]);
  }

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
}
