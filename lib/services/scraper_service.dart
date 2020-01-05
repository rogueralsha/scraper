import 'package:uuid/uuid.dart';
import 'dart:js';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:angular/angular.dart';
import 'package:scraper/results/page_info.dart';
import 'package:scraper/globals.dart';
import 'package:scraper/web_extensions/web_extensions.dart' as browser;
export '../results/page_info.dart';

@Injectable()
class ScraperService {
  static final Logger _log = new Logger("ScraperService");

  ScraperService() {}

  Future<browser.Port> openPort() async {
    try {
      final List<browser.Tab> tabs = await browser.tabs
          .query(active: true, currentWindow: true);
      browser.Tab tab = tabs[0];
      _log.info("Active tab url: ${tab.url}");
      return browser.tabs
          .connect(tab.id, name: new Uuid().v4());
    } catch (e, st) {
      _log.info("openPort", e, st);
      _log.info("Falling back on event page to connect");
      // Indicates that chrome.tabs is unavailable, indicating that we're in the content
      // so we use the background page as a relay instead.
      return browser.runtime.connect();
    }
  }

  Future<PageInfo> getScrapeResults(String url) async {
    _log.finest("getScrapeResults start");

    try {
      final browser.Port p = await openPort();
      PageInfo results;
      try {
        p.postMessage(
            {messageFieldUrl: url, messageFieldCommand: scrapePageCommand});
        await for (JsObject message in p.onMessage) {
          if (message[messageFieldEvent] == scrapeDoneEvent) {
            _log.info("Reults message received");
            _log.info(message);
            results = new PageInfo.fromJsObject(message[messageFieldData]);
            break;
          } else {
            throw new Exception("Unrecognized object received in message");
          }
        }
      } finally {
        p.disconnect();
        _log.info("Disconnecting from scraper port");
      }
      return results;
    } finally {
      _log.finest("getScrapeResults end");
    }
  }
}
