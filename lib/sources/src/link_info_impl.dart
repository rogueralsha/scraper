import 'package:logging/logging.dart';
import 'package:scraper/results/link_info.dart';
import '../imgur_source.dart';
import 'dart:html';
export 'package:scraper/results/link_info.dart';

class LinkInfoImpl extends LinkInfo {
  static final Logger _log = new Logger("ScrapeResultImpl");

  LinkInfoImpl(String url, String sourceUrl,
      {type: LinkType.image,
      String filename: null,
      autoDownload: true,
      thumbnail: null,
      date: null,
      select: true,
        referrer: null})
      : super(
            sourceUrl: sourceUrl,
            type: type,
            autoDownload: autoDownload,
            thumbnail: thumbnail,
            date: date,
            select: select,
      referrer: referrer) {

    url = ImgurSource.convertMobileUrl(url);

    _log.info("Creating " + type.toString() + " link: " + url);
    this.url = _resolvePartialUrl(Uri.decodeComponent(url));

    if (filename == null) {
      this.filename = _getFileName(url);
      if (this.filename.length == 0) {
        this.filename = url;
      }
    } else {
      _log.info("Provided filename: " + filename);
      this.filename = filename;
    }

    if (thumbnail == null && type == LinkType.image) {
      this.thumbnail = url;
    }
  }

  String _resolvePartialUrl(url) {
    AnchorElement ele = document.createElement("a");
    ele.href = url;
    return ele.href;
  }

  String _getFileName(link) => Uri
      .decodeComponent(link.substring(link.lastIndexOf('/') + 1).split("?")[0]);
}
