import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'a_source.dart';
import 'ariel_rebel_source.dart';
import 'artstation_source.dart';
import 'blogger_source.dart';
import 'comic_art_community_source.dart';
import 'comic_art_fans_source.dart';
import 'cosplay_erotica_source.dart';
import 'cyberdrop_source.dart';
import 'danbooru_source.dart';
import 'deviantart_source.dart';
import 'e_hentai_source.dart';
import 'erome_source.dart';
import 'etc_source.dart';
import 'facebook_source.dart';
import 'famous_internet_girls_source.dart';
import 'fandom_source.dart';
import 'fetish_network_source.dart';
import 'gelbooru.dart';
import 'gfycat_source.dart';
import 'haruhisky_source.dart';
import 'hentai_foundry_source.dart';
import 'hentai_united_source.dart';
import 'i_love_bianca_source.dart';
import 'ibradome_source.dart';
import 'image_fap_source.dart';
import 'imgur_source.dart';
import 'instagram_source.dart';
import 'livedoor_source.dart';
import 'minitokyo_source.dart';
import 'newgrounds_source.dart';
import 'neocoill_source.dart';
import 'only_fans.dart';
import 'other_source.dart';
import 'patreon_source.dart';
import 'pinupfiles_source.dart';
import 'put_mega_source.dart';
import 'queencomplex_source.dart';
import 'reddit_source.dart';
import 'redgifs_source.dart';
import 'rincity_source.dart';
import 'rule34xxx_source.dart';
import 'sexypattycake_source.dart';
import 'shimmie_source.dart';
import 'slushe_source.dart';
import 'sports_illustrated_source.dart';
import 'suicide_girls_source.dart';
import 'tessa_fowler_source.dart';
import 'thothub_source.dart';
import 'tiny_tiny_rss_source.dart';
import 'tumblr_source.dart';
import 'twitter_source.dart';
import 'fighters_generation_source.dart';
import 'vnalive_live_source.dart';
import 'webmshare_source.dart';
import 'wordpress_source.dart';

export 'a_source.dart';

const List<dynamic> sourceProviders = const <dynamic>[
  const ClassProvider(DeviantArtSource),
  const ClassProvider(RedditSource),
  const ClassProvider(ArielRebelSource),
  const ClassProvider(ArtStationSource),
  const ClassProvider(LivedoorSource),
  const ClassProvider(ComicArtCommunitySource),
  const ClassProvider(ComicArtFansSource),
  const ClassProvider(CyberDropSource),
  const ClassProvider(ShimmieSource),
  const ClassProvider(FandomSource),
  const ClassProvider(HentaiFoundrySource),
  const ClassProvider(InstagramSource),
  const ClassProvider(ImgurSource),
  const ClassProvider(ImageFapSource),
  const ClassProvider(GelbooruSource),
  const ClassProvider(GfycatSource),
  const ClassProvider(BloggerSource),
  const ClassProvider(TumblrSource),
  const ClassProvider(OnlyFansSource),
  const ClassProvider(TwitterSource),
  const ClassProvider(FacebookSource),
  const ClassProvider(EtcSource),
  const ClassProvider(DanbooruSource),
  const ClassProvider(TinyTinyRSSSource),
  const ClassProvider(NeoCoillSource),
  const ClassProvider(ILoveBiancaSource),
  const ClassProvider(FetishNetworkSource),
  const ClassProvider(IbradomeSource),
  const ClassProvider(EromeSource),
  const ClassProvider(FamousInternetGirlsSource),
  const ClassProvider(PatreonSource),
  const ClassProvider(WordpressSource),
  const ClassProvider(CosplayEroticaSource),
  const ClassProvider(WebmShareSource),
  const ClassProvider(FightersGenerationSource),
  const ClassProvider(EHentaiSource),
  const ClassProvider(PinupfilesSource),
  const ClassProvider(NewgroundsSource),
  const ClassProvider(SuicideGirlsSource),
  const ClassProvider(VNALiveSource),
  const ClassProvider(MinitokyoSource),
  const ClassProvider(SportsIllustratedSource),
  const ClassProvider(PutMegaSource),
  const ClassProvider(ThothubSource),
  const ClassProvider(RinCitySource),
  const ClassProvider(HentaiUnitedSource),
  const ClassProvider(HaruhiskySource),
  const ClassProvider(RedgifsSource),
  const ClassProvider(SexypattycakeSource),
  const ClassProvider(QueencomplexSource),
  const ClassProvider(TessaFowlerSource),
  const ClassProvider(Rule34XXXSource),
  const ClassProvider(SlusheSource),
  const ClassProvider(OtherSource),
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
      ArielRebelSource arielRebelSource,
      ImageFapSource imageFapSource,
      ImgurSource imgurSource,
      GelbooruSource gelbooruSource,
      GfycatSource gfycatSource,
      BloggerSource bloggerSource,
      ILoveBiancaSource iLoveBiancaSource,
      DanbooruSource danbooruSource,
      FandomSource fandomSource,
      TumblrSource tumblrSource,
      TwitterSource twitterSource,
      FacebookSource facebookSource,
      EtcSource etcSource,
      EHentaiSource eHentaiSource,
      NeoCoillSource neoCoillSource,
      FamousInternetGirlsSource famousInternetGirlsSource,
      TinyTinyRSSSource ttRssSource,
      EromeSource eromeSource,
      IbradomeSource ibradomeSource,
      PatreonSource patreonSource,
      FetishNetworkSource fetishNetworkSource,
      WordpressSource wordpressSource,
      FightersGenerationSource fighersGenerationSource,
      PinupfilesSource pinupfilesSource,
      WebmShareSource webmShareSource,
      NewgroundsSource newgroundsSource,
      LivedoorSource livedoorSource,
      VNALiveSource vnaLiveSource,
      OnlyFansSource onlyFansSource,
      MinitokyoSource minitokyoSource,
      SportsIllustratedSource sportsIllustratedSource,
      ThothubSource thothubSource,
      SuicideGirlsSource suicideGirlsSource,
      HentaiUnitedSource hentaiUnitedSource,
      PutMegaSource putMegaSource,
      RinCitySource rincitySource,
      RedgifsSource redgifsSource,
      SexypattycakeSource sexypattycakeSource,
      QueencomplexSource queencomplexSource,
      TessaFowlerSource tessaFowlerSource,
      CosplayEroticaSource cosplayEroticaSource,
      Rule34XXXSource rule34XXXSource,
      SlusheSource slusheSource,
  CyberDropSource cyberDropSource,
      HaruhiskySource haruhiskySource,
      OtherSource otherSource) {
    sourceInstances.addAll([
      etcSource,
      deviantArtSource,
      arielRebelSource,
      redditSource,
      artstationSource,
      comicArtCommunity,
      comicartFanSource,
      hentaiFoundrySource,
      instagramSource,
      imgurSource,
      imageFapSource,
      gfycatSource,
      gelbooruSource,
      tumblrSource,
      twitterSource,
      facebookSource,
      eHentaiSource,
      fandomSource,
      fighersGenerationSource,
      fetishNetworkSource,
      eromeSource,
      putMegaSource,
      patreonSource,
      webmShareSource,
      onlyFansSource,
      iLoveBiancaSource,
      pinupfilesSource,
      newgroundsSource,
      minitokyoSource,
      ibradomeSource,
      vnaLiveSource,
      danbooruSource,
      sportsIllustratedSource,
      thothubSource,
      cosplayEroticaSource,
      cyberDropSource,
      sexypattycakeSource,
      haruhiskySource,
      tessaFowlerSource,
      queencomplexSource,
      suicideGirlsSource,
      // These are generic source, keep at the bottom
      bloggerSource,
      livedoorSource,
      neoCoillSource,
      famousInternetGirlsSource,
      ttRssSource,
      shimmieSource,
      wordpressSource,
      rincitySource,
      hentaiUnitedSource,
      redgifsSource,
      rule34XXXSource,
      slusheSource,
      // This is the catch-all generic source, should always be last
      otherSource
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
