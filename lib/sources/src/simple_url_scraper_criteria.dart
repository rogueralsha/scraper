import 'dart:html';
import '../../results/link_info.dart';

typedef bool ValidateLinkInfo(LinkInfo li, Element ele);

class SimpleUrlScraperCriteria {
  final LinkType linkType;
  final String linkSelector;
  final String thumbnailSubSelector;
  final ValidateLinkInfo validateLinkInfo;
  final int limit;
  SimpleUrlScraperCriteria(this.linkType, this.linkSelector,
      {this.thumbnailSubSelector: "img",
      this.validateLinkInfo: null,
      this.limit: -1});
}
