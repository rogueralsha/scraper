import 'package:scraper/globals.dart';
import 'dart:html';
import 'package:scraper/results/scrape_results.dart';
import 'dart:async';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
export 'package:scraper/results/scrape_results.dart';
export 'scrape_result_impl.dart';

abstract class ASource {
  static final _log = new Logger("ASource");

  Future<ScrapeResults> scrapePage(String url, Document document);

  bool attachPageListener(String url, Document document) => false;

  static Future<int> getCurrentTabId() async {
    _log.info("Getting current tab id");
    chrome.Port p = chrome.runtime.connect(null, new chrome.RuntimeConnectParams(name: new Uuid().v4()));
    try {
      p.postMessage({messageFieldCommand: getTabIdCommand});
      chrome.OnMessageEvent e = await p.onMessage.first;
      _log.info("Current tab ID is: ${e.message[messageFieldTabId]}");
      return e.message[messageFieldTabId];
    } finally {
      p.disconnect();
    }
  }
}