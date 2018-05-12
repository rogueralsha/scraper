import 'a_source.dart';
import 'deviantart_source.dart';
import 'artstation_source.dart';
import 'reddit_source.dart';
import 'comic_art_fans_source.dart';
import 'comic_art_community_source.dart';
import 'shimmie_source.dart';
import 'hentai_foundry_source.dart';
export 'a_source.dart';

final List<ASource> sourceInstances = <ASource>[
  new DeviantArtSource(),
  new RedditSource(),
  new ArtStationSource(),
  new ComicArtCommunitySource(),
  new ComicArtFansSource(),
  new ShimmieSource(),
  new HentaiFoundrySource()
];
