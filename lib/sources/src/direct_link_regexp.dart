import 'package:scraper/results/link_type.dart';

class DirectLinkRegExp {
  final LinkType linkType;
  final RegExp regExp;
  final bool checkForRedirect;

  DirectLinkRegExp(this.linkType, this.regExp, {this.checkForRedirect = false});
}
