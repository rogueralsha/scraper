import 'dart:html';
import '../../results/link_info.dart';


typedef bool ValidateLinkInfo(LinkInfo li, Element ele);

class SimpleUrlScraperCriteria {
  final LinkType linkType;
  final String linkSelector;
  final String thumbnailSubSelector;
  final ValidateLinkInfo validateLinkInfo;
  final int limit;
  final bool evaluateLinks;
  final RegExp linkRegExp;
  SimpleUrlScraperCriteria(this.linkType, this.linkSelector,
      {this.thumbnailSubSelector= "img",
      this.validateLinkInfo,
      this.limit= -1,
      this.evaluateLinks= false,
      this.linkRegExp});
}
