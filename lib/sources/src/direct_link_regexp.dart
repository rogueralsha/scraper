import 'package:scraper/results/link_type.dart';

class DirectLinkRegExp {
  final LinkType linkType;
  final RegExp regExp;

  DirectLinkRegExp(this.linkType, this.regExp);
}
