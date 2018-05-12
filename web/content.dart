import 'package:scraper/globals.dart';
import 'dart:async';
import 'dart:js';
import 'dart:html';
import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:scraper/results_dialog.template.dart' as ng;
import 'package:scraper/sources/sources.dart';
import 'package:scraper/services/scraper_service.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

final Logger _log = new Logger("content.dart");

StreamSubscription pageInfoSub;
StreamSubscription linkInfoSub;
StreamSubscription scrapeDoneSub;

Future<Null> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(new LogPrintHandler());

  int tabId = await getCurrentTabId();

  chrome.runtime.onMessage.listen((chrome.OnMessageEvent e) async {
    _log.fine("onMesage handler start");

    try {
      _log.fine("Message received");
      _log.finer(context['JSON'].callMethod('stringify', [e.message]));

      Map request = e.message;
      String command = request[messageFieldCommand];
      if (command != startScrapeCommand) return;

      _log.info(
          "Message to start scraping ${request[messageFieldUrl]} receive, starting scraping");
      if(pageInfoSub!=null) {
        await pageInfoSub.cancel();
        pageInfoSub = null;
      }
      if(linkInfoSub!=null) {
        await linkInfoSub.cancel();
        linkInfoSub = null;
      }

      String url = window.location.href;
      for (ASource source in sourceInstances) {
        _log.finest("Checking if $source can scrape source");
        if (source.canScrapePage(url, document:  document)) {
          _log.finest("It can!");
          pageInfoSub = source.onScrapeUpdateEvent.listen((dynamic e)  async {
            _log.fine("onScrapeUpdateEvent stream event received");
            if(e is PageInfo) {
              _log.finest("Data is PageInfo, forwarding");
              await chrome.runtime.sendMessage(
                  {
                    messageFieldEvent: pageInfoEvent,
                    messageFieldTabId: tabId,
                    messageFieldData: e.toJson()
                  });
            } else if(e is LinkInfo) {
              _log.finest("Data is LinkInfo, forwarding");
              await chrome.runtime.sendMessage(
                  {messageFieldEvent: linkInfoEvent, messageFieldTabId: tabId, messageFieldData: e.toJson()});

            } else if(e==scrapeDoneEvent) {
              _log.fine("Scrape done stream event received");
              await chrome.runtime.sendMessage(
                  {messageFieldEvent: scrapeDoneEvent, messageFieldTabId: tabId});

            }
          });

          await source.startScrapingPage(url, document);
          break;
        }
      }
      _log.finest("End of source checking loop");
    } catch (e, st) {
      _log.severe("getPageMedia message", e, st);
    } finally {
      _log.finest("onMesage handler end");
      }
  });

  if(!inIframe()) {
    document.body.append(document.createElement("results-dialog"));

    runApp(ng.ResultsDialogNgFactory);
  }
}

//
//void attachMonitor(String url, Document document) {
//  for (ASource source in sources) {
//    bool result = source.attachPageListener(url, document);
//    if (result) {
//      _log.info("Page being monitored by $source");
//      return;
//    }
//  }
//}
//
Future<Null> startScraping(String url, Document document) async {}
