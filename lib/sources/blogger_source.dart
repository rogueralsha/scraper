import 'package:logging/logging.dart';

import 'a_source.dart';
import 'src/simple_url_scraper.dart';

class BloggerSource extends ASource {
  static final Logger logImpl = new Logger("BloggerSource");

  @override
  String get sourceName => "blogger";

  static final RegExp _regExp =
      new RegExp(r"^https?://([^.]+)\.blogspot\.com/.*$", caseSensitive: false);

  static final RegExp _postRegExp = new RegExp(
      r"^https?://([^.]+)\.blogspot\.com/\d{4}/\d{2}/.*",
      caseSensitive: false);

  static final RegExp _contentRegExp = new RegExp(
      r"^https?://\d+\.([^.]+)\.blogspot\.com/-.+",
      caseSensitive: false);

  // Possible way to get bigger blogger images:
  //https://4.bp.blogspot.com/-VWiiRMBtTc8/Wo4nienMx9I/AAAAAAAAllM/xWSeAYeT_W4-v_1bfiEkhNkGz-W7G_ZEQCLcBGAs/s0/1516297880918-2.jpg=s0?imgmax=0
  //https://4.bp.blogspot.com/-VWiiRMBtTc8/Wo4nienMx9I/AAAAAAAAllM/xWSeAYeT_W4-v_1bfiEkhNkGz-W7G_ZEQCLcBGAs/s1600/1516297880918-2.jpg

  BloggerSource(SettingsService settings) : super(settings) {
    this
        .directLinkRegexps
        .add(new DirectLinkRegExp(LinkType.file, _contentRegExp));

    this.urlScrapers.add(new SimpleUrlScraper(this, _postRegExp,
        [new SimpleUrlScraperCriteria(LinkType.image, "div.post-body a")]));

    this.urlScrapers.add(new SimpleUrlScraper(
          this,
          _regExp,
          [
            new SimpleUrlScraperCriteria(LinkType.page, "a.timestamp-link"),
            new SimpleUrlScraperCriteria(
                LinkType.page, "div.blog-pager a.blog-pager-older-link",
                limit: 1)
          ],
        ));
  }
}
