import 'package:scraper/globals.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:js';
import 'package:scraper/globals.dart';
import 'dart:html';
import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:scraper/results_dialog.template.dart' as ng;
import 'package:scraper/sources/sources.dart';
import 'package:scraper/services/scraper_service.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

final _log = new Logger("content.dart");

final List<ASource> sources = <ASource>[new DeviantArtSource()];


Future<Null> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(new LogPrintHandler());

  ScraperService service = new ScraperService();

  chrome.runtime.onConnect.listen((chrome.Port p) {
    _log.info("Connection opened: ${p.name}");

    StreamSubscription messageSub;
    messageSub = p.onMessage.listen((chrome.OnMessageEvent e) async {
      try {
        _log.info("Message received on port ${p.name}");
        _log.info(context['JSON'].callMethod('stringify',[e.message]));

        Map request = e.message;
        String command = request[messageFieldCommand];
        if(command!=scrapePageCommand)
          return;

        if (request[messageFieldUrl]==null||
            request[messageFieldUrl] == window.location.href) {
          try {
            _log.info(
                "Message to scrape ${request[messageFieldUrl]} receive, scraping page");
            ScrapeResults results = await scrape(
                window.location.href, document);
            Map resultMap = results.toJson();
            _log.info("Sending scrape results:");
            _log.info(resultMap);
            p.postMessage(new JsObject.jsify({messageFieldEvent: scrapeDoneEvent, messageFieldData: resultMap }));
          } finally {
            p.disconnect();
          }
        }
      } catch (e, st) {
        _log.severe("getPageMedia message", e, st);
      }
    });

  });


  document.body.append(document.createElement("results-dialog"));

  runApp(ng.ResultsDialogNgFactory);

}


void attachMonitor(String url, Document document) {
  for (ASource source in sources) {
    bool result = source.attachPageListener(url, document);
    if (result) return;
  }
}

Future<ScrapeResults> scrape(String url, Document document) async {
  for (ASource source in sources) {
    ScrapeResults results = await source.scrapePage(url, document);
    if (results.matchFound) return results;
  }
  return new ScrapeResults(await ASource.getCurrentTabId());
}
