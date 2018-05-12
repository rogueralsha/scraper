import 'package:logging/logging.dart';
import '../results/link_info.dart';
import 'imgur_source.dart';
import 'dart:html';
export '../results/link_info.dart';

class LinkInfoImpl extends LinkInfo {
  static final _log = new Logger("ScrapeResultImpl");

  LinkInfoImpl(String url,
      {type: LinkType.image,
      String filename: null,
      autoDownload: true,
      thumbnail: null,
      date: null,
      select: true,
        referrer: null})
      : super(
            type: type,
            autoDownload: autoDownload,
            thumbnail: thumbnail,
            date: date,
            select: select,
      referrer: referrer) {
    if (ImgurSource.postRegexp.hasMatch(url)) {
      // Mobile imgur links redirect, so we need to filter them a bit
      Match m = ImgurSource.postRegexp.firstMatch(url);
      if (m.group(1) == "m.") {
        url = url.replaceAll("//m.imgur.", "//imgur.");
      }
    }

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
