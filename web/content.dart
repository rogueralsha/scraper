import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:angular/angular.dart';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:scraper/globals.dart';
import 'package:scraper/results_dialog.template.dart' as ng;
import 'package:scraper/services/scraper_service.dart';
import 'package:scraper/services/settings_service.dart';
import 'package:scraper/sources/sources.dart';
import 'package:uuid/uuid.dart';

String pageId = new Uuid().v4().toString();

Future<Null> main() async {

  Logger.root.level = await settings.getLoggingLevel();
  Logger.root.onRecord.listen(new LogPrintHandler(messageFormat: "%t\t$pageId\t%n\t[%p]:\t%m"));
  _log.info("Logging set to ${Logger.root.level.name}");
  _log.finest("main()");

  final int tabId = await getCurrentTabId();

  final ASource source = getScraperForSite(window.location.href, document);

  if (source != null) {
    chrome.runtime.onMessage.listen((chrome.OnMessageEvent e) async {
      _log.fine("onMesage handler start");

      try {
        _log.fine("Message received");
        _log.finer(context['JSON'].callMethod('stringify', [e.message]));

        final Map request = e.message;
        final String command = request[messageFieldCommand];
        if (command != startScrapeCommand) return;

        final String targetUrl = request[messageFieldUrl];
        if(targetUrl!=window.location.href) {
          _log.warning("Scrape request is not for this url (${window.location.href}), it is for $targetUrl");
          return;
        }
        _log.finer("Request matches this url ${window.location.href}");

        _log.info(
            "Message to start scraping ${request[messageFieldUrl]} receive, starting scraping");
        if (pageInfoSub != null) {
          await pageInfoSub.cancel();
          pageInfoSub = null;
        }
        pageInfoSub = source.onScrapeUpdateEvent.listen((dynamic e) async {
          _log.fine("onScrapeUpdateEvent stream event received");
          if (e is PageInfo) {
            _log.finest("Data is PageInfo, forwarding");
            await chrome.runtime.sendMessage(<String, dynamic>{
              messageFieldEvent: pageInfoEvent,
              messageFieldTabId: tabId,
              messageFieldData: e.toJson()
            });
          } else if (e is LinkInfo) {
            _log.finest("Data is LinkInfo, forwarding");
            await chrome.runtime.sendMessage({
              messageFieldEvent: linkInfoEvent,
              messageFieldTabId: tabId,
              messageFieldData: e.toJson()
            });
          } else if (e == scrapeDoneEvent) {
            _log.fine("Scrape done stream event received");
            await chrome.runtime.sendMessage(
                {messageFieldEvent: scrapeDoneEvent, messageFieldTabId: tabId});
          }
        });

        await source.startScrapingPage(window.location.href, document);
        _log.finest("End of source checking loop");
      } on Exception catch (e, st) {
        _log.severe("getPageMedia message", e, st);
      } finally {
        _log.finest("onMesage handler end");
      }
    });

    if (!inIframe()) {
      document.body.append(document.createElement("results-dialog"));

      runApp(ng.ResultsDialogNgFactory);
    }
  } else {
    _log.warning("This page is not supported by scraper");
  }
}

StreamSubscription pageInfoSub;
SettingsService settings = new SettingsService();

final Logger _log = new Logger("content.dart");
