import 'a_source.dart';
import 'package:logging/logging.dart';

class EtcSource extends ASource {
  static final Logger _log = new Logger("EtcSource");

  static final RegExp _squareSpaceStaticServerRegExp = new RegExp(
      r"https?://static\d+\.squarespace\.com/.*",
      caseSensitive: false);
  static final RegExp _catboxRegExp =
  new RegExp(r"https?://files\.catbox\.moe/.*", caseSensitive: false);
  static final RegExp _uploaddirRegExp =
  new RegExp(r"https?://uploadir\.com/u/.*", caseSensitive: false);
  static final RegExp _uploadsRuRegExp =
  new RegExp(r"https?://[a-z0-9]+\.uploads\.ru/.*", caseSensitive: false);

  EtcSource() {
    this.directLinkRegexps.add(new DirectLinkRegExp(LinkType.file,_squareSpaceStaticServerRegExp));
    this.directLinkRegexps.add(new DirectLinkRegExp(LinkType.file,_catboxRegExp));
    this.directLinkRegexps.add(new DirectLinkRegExp(LinkType.file,_uploaddirRegExp));
    this.directLinkRegexps.add(new DirectLinkRegExp(LinkType.file,_uploadsRuRegExp));
  }
}
