import 'package:uuid/uuid.dart';
import 'dart:js';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:angular/angular.dart';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:scraper/results/page_info.dart';
import 'package:scraper/globals.dart';
export '../results/page_info.dart';

@Injectable()
class ScraperService {
  static final Logger _log = new Logger("ScraperService");

  ScraperService() {}

  Future<chrome.Port> openPort() async {
    try {
      List<chrome.Tab> tabs = await chrome.tabs
          .query(new chrome.TabsQueryParams(active: true, currentWindow: true));
      chrome.Tab tab = tabs[0];
      _log.info("Active tab url: ${tab.url}");
      return chrome.tabs
          .connect(tab.id, new chrome.TabsConnectParams(name: new Uuid().v4()));
    } catch (e, st) {
      _log.info("openPort", e, st);
      _log.info("Falling back on event page to connect");
      // Indicates that chrome.tabs is unavailable, indicating that we're in the content
      // so we use the background page as a relay instead.
      return chrome.runtime.connect(null, new chrome.RuntimeConnectParams());
    }
  }

  Future<PageInfo> getScrapeResults(String url) async {
    _log.finest("getScrapeResults start");

    try {
      final chrome.Port p = await openPort();
      PageInfo results;
      try {
        p.postMessage(
            {messageFieldUrl: url, messageFieldCommand: scrapePageCommand});
        await for (chrome.OnMessageEvent e in p.onMessage) {
          final JsObject message = e.message;
          if (message[messageFieldEvent] == scrapeDoneEvent) {
            _log.info("Reults message received");
            _log.info(e.message);
            results = new PageInfo.fromJsObject(e.message[messageFieldData]);
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
