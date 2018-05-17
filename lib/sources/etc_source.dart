import 'a_source.dart';
import 'package:logging/logging.dart';

class EtcSource extends ASource {
  static final Logger _log = new Logger("EtcSource");

  static final RegExp _squareSpaceStaticServerRegExp =
      new RegExp("https?://static\\d+\\.squarespace\\.com/.*", caseSensitive: false);
  EtcSource() {
    this.directLinkRegexps.add(_squareSpaceStaticServerRegExp);

  }
}
