import 'a_source.dart';
import 'package:logging/logging.dart';

class FacebookSource extends ASource {
  static final Logger _log = new Logger("FacebookSource");

  static final RegExp _contentServerRegExp =
      new RegExp("https?://.+\\.fbcdn\\.net/.*", caseSensitive: false);
  //static final RegExp _albumRegExp = new RegExp("https?://[^\\.]+\\.facebook\\.com/.*album_id=(\\d+)", caseSensitive: false);
  //static final RegExp _photoRegExp = new RegExp("https?://[^\\.]+\\.facebook\\.com/.*\\/photos\\/.*", caseSensitive: false);

  FacebookSource() {
    this.directLinkRegexps.add(_contentServerRegExp);

//    this.urlScrapers.add(new SimpleUrlScraper(this, _albumRegExp, [
//      new SimpleUrlScraperCriteria(LinkType.page, "div#content_container ._2eea a")]));
//    this.urlScrapers.add(new SimpleUrlScraper(this, _photoRegExp, [
//      new SimpleUrlScraperCriteria(LinkType.image, "li[data-action-type='download_photo'] a")]));
  }

//  Future<Null> facebookSetPageInfo (PageInfo p, Match m, String url, Document d) async {
//    _log.finest("facebookSetPageInfo start");
//    p.saveByDefault = false;
//    p.artist = "facebook";
//  }
//
//  Future<Null> scrapeAlbumLinkInfo(String url, Document d) {
//    _log.finest("scrapeAlbumLinkInfo start");
//    Completer completer = new Completer();
//
//
//
//
//    request.open("GET", "https://imgur.com/ajaxalbums/getimages/" + albumHash + "/hit.json", async: true);
//    request.send();
//
//    return completer.future;
//  }

}
