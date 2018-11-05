import 'dart:html';

import 'package:logging/logging.dart';
import 'package:scraper/results/link_info.dart';

import 'package:scraper/globals.dart';

import '../imgur_source.dart';
export 'package:scraper/results/link_info.dart';

class LinkInfoImpl extends LinkInfo {
  static final Logger _log = new Logger("LinkInfoImpl");

  LinkInfoImpl(String url, String sourceUrl,
      {LinkType type = LinkType.image,
      String filename,
      bool autoDownload = true,
      String thumbnail,
      DateTime date,
      bool select = true,
      String referrer})
      : super(
            sourceUrl: sourceUrl,
            type: type,
            autoDownload: autoDownload,
            thumbnail: thumbnail,
            date: date,
            select: select,
            referrer: referrer) {
    if (url?.isEmpty ?? true) {
      throw new ArgumentError.notNull("url");
    }
    if (sourceUrl?.isEmpty ?? true) {
      throw new ArgumentError.notNull("sourceUrl");
    }

    url = ImgurSource.convertMobileUrl(url);

    _log.fine("Creating ${type.toString()} link: $url");
    this.url = _resolvePartialUrl(Uri.decodeComponent(url));

    if (filename == null) {
      this.filename = getFileNameFromUrl(url);
      if (this.filename.isEmpty) {
        this.filename = url;
      }
    } else {
      _log.fine("Provided filename: $filename");
      this.filename = filename;
    }

    if (thumbnail == null && type == LinkType.image) {
      this.thumbnail = url;
    }
  }



  String _resolvePartialUrl(String url) {
    final AnchorElement ele = new AnchorElement()..href = url;
    return ele.href;
  }
}
