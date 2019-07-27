import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:logging/logging.dart';
import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'package:scraper/results_dialog.dart';
import 'package:scraper/services/scraper_service.dart';
import 'package:scraper/services/settings_service.dart';
import 'package:scraper/sources/sources.dart';
import 'package:scraper/sources/sources.dart';
import 'package:scraper/web_extensions/web_extensions.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid.dart';

import 'globals.dart';
import 'results_dialog.dart';
import 'services/scraper_service.dart';

// AngularDart info: https://webdev.dartlang.org/angular
// Components info: https://webdev.dartlang.org/components

@Component(
  selector: 'scraper-component',
  template: '<results-dialog *ngIf="showDialog"></results-dialog>',
  directives: [ResultsDialog, NgIf],
  providers: [
    const ClassProvider(SettingsService),
    sourceProviders,
    const ClassProvider(Sources),
  ],
)
class ScraperComponent implements OnInit {
  static final Logger _log = new Logger("ScraperComponent");

  final String _pageId = new Uuid().v4().toString();

  final Sources _sources;

  StreamSubscription<dynamic> _pageInfoSub;

  final SettingsService _settings;

  bool showDialog = false;

  ScraperComponent(this._sources, this._settings) {
    Logger.root.onRecord.listen(logToConsole);
    _log.info("Logging set to ${Logger.root.level.name}");
  }

  @override
  Future<Null> ngOnInit() async {
    Logger.root.level = await _settings.getLoggingLevel();

    final int tabId = await getCurrentTabId();

    final ASource source =
        _sources.getScraperForSite(window.location.href, document);

    if (source != null) {
      browser.runtime.onMessage.listen((OnMessageEvent e) async {
        _log.fine("onMesage handler start");

        try {
          _log
            ..fine("Message received")
            ..finer(jsVarDump(e.message));

          final JsObject request = e.message;
          final String command = request[messageFieldCommand];
          _log.finest("Command $command received");
          switch (command) {
            case startScrapeCommand:
              break;
            case loadWholePageCommand:
              _log.finest("Start loadWholePage for source");
              if (source != null) await source.loadWholePage();
              return;
            default:
              return;
          }

          final String targetUrl = request[messageFieldUrl];
          if (targetUrl != window.location.href) {
            _log.warning("Scrape request is not for this url (${window.location
                    .href}), it is for $targetUrl");
            return;
          }
          _log.finer("Request matches this url ${window.location.href}");

          _log.info(
              "Message to start scraping ${request[messageFieldUrl]} receive, starting scraping");
          if (_pageInfoSub != null) {
            await _pageInfoSub.cancel();
            _pageInfoSub = null;
          }
          _pageInfoSub = source.onScrapeUpdateEvent.listen((dynamic e) async {
            _log.fine("onScrapeUpdateEvent stream event received");
            if (e is PageInfo) {
              _log.finest("Data is PageInfo, forwarding");
              await browser.runtime.sendMessage(<String, dynamic>{
                messageFieldEvent: pageInfoEvent,
                messageFieldTabId: tabId,
                messageFieldData: e.toJson()
              });
            } else if (e is LinkInfo) {
              _log.finest("Data is LinkInfo, forwarding");
              await browser.runtime.sendMessage({
                messageFieldEvent: linkInfoEvent,
                messageFieldTabId: tabId,
                messageFieldData: e.toJson()
              });
            } else if (e == scrapeDoneEvent) {
              _log.fine("Scrape done stream event received");
              await browser.runtime.sendMessage({
                messageFieldEvent: scrapeDoneEvent,
                messageFieldTabId: tabId
              });
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
        showDialog = true;
      }
    } else {
      _log.warning("This page is not supported by scraper");
    }
  }
}
