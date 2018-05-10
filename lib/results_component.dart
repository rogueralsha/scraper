import 'dart:js';
import 'package:uuid/uuid.dart';
import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'dart:collection';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'src/todo_list/todo_list_component.dart';
import 'package:logging/logging.dart';
import 'services/scraper_service.dart';
import 'globals.dart';
import 'package:chrome/chrome_ext.dart' as chrome;

// AngularDart info: https://webdev.dartlang.org/angular
// Components info: https://webdev.dartlang.org/components

@Component(
  selector: 'results-viewer',
  styleUrls: ['results_component.css'],
  templateUrl: 'results_component.html',
  directives: [TodoListComponent, NgFor, materialDirectives, NgIf],
  providers: [const ClassProvider(ScraperService), materialProviders],
)
class ResultsComponent implements OnInit {
  final _log = new Logger("ResultsComponent");

  bool loaded = false;
  bool processing = false;
  bool waitForLoad = true;
  int progress = 0;

  final ScraperService _scraper;

  ScrapeResults results = new ScrapeResults(-1);

  ResultsComponent(this._scraper);
// Nothing here yet. All logic is in TodoListComponent.

  void refreshButtonClick() {
    try {
      results = new ScrapeResults(-1);
      refresh();
    } catch(e,st) {
      _log.severe("refreshButtonClick", e, st);
    }
 }



  void openAllButtonClick() {
    try {
      processing = true;
      Queue<ScrapeResult> toOpen = new Queue<ScrapeResult>.of(results.results.where((ScrapeResult r) => r.select));

      if(toOpen.isEmpty) {
        _log.info("Nothing to open, ending");
        return;
      }

      int total = toOpen.length;
      int loaded = 0;
      
      _log.info("Wait is set to $waitForLoad");

      chrome.Port p = chrome.runtime.connect(null, new chrome.RuntimeConnectParams(name: new Uuid().v4()));
      StreamSubscription messageSub;
      messageSub = p.onMessage.listen((chrome.OnMessageEvent e) {
        if(e.message==endMessageEvent) {
          processing = false;
          messageSub.cancel();
          p.disconnect();
        }
        loaded++;
        this.progress = ((loaded/total)*100).round();
        if(waitForLoad&&toOpen.isNotEmpty) {
          ScrapeResult r = toOpen.removeFirst();
          p.postMessage({messageFieldCommand: openTabCommand, messageFieldUrl: r.url});
        }
      });

      if(waitForLoad) {
        ScrapeResult r = toOpen.removeFirst();
        p.postMessage({messageFieldCommand: openTabCommand, messageFieldUrl: r.url});
      } else {
        while(toOpen.isNotEmpty) {
          ScrapeResult r = toOpen.removeFirst();
          p.postMessage({messageFieldCommand: openTabCommand, messageFieldUrl: r.url});
        }
      }

    } catch(e,st) {
      _log.severe("openAllButtonClick",e,st);
    }
  }
  void downloadButtonClick({bool close: false}) async {
    try {
      processing = true;
      List<ScrapeResult> toDownload = new List<ScrapeResult>.from(results.results.where((ScrapeResult r) => r.select));

      if(toDownload.isEmpty) {
        _log.info("Nothing to download, ending");
        return;
      }

      int total = toDownload.length;
      int loaded = 0;

      chrome.Port p = chrome.runtime.connect(null, new chrome.RuntimeConnectParams(name: new Uuid().v4()));
      try {
        _log.info("Getting first item from queue");

        ScrapeResult r = toDownload.removeAt(0);

        _sendMessageForScrapeResult(p, r);
        await for (chrome.OnMessageEvent e in p.onMessage) {
          _log.info("Message received during download process");
          _log.info(context['JSON'].callMethod('stringify', [e.message]));
          if (e.message == endMessageEvent) {
            processing = false;
            break;
          } else if (e.message.hasProperty(messageFieldEvent)) {
            String event = e.message[messageFieldEvent];
            switch(event) {
              case tabLoadedMessageEvent:
              // Indicates that the page had a sub page
                _log.info("Tab loaded (${e
                    .message[messageFieldTabId]}) event received, sending scrape signal to page");
                p.postMessage({
                  messageFieldCommand: scrapePageCommand,
                  messageFieldTabId: e.message[messageFieldTabId]
                });
                continue;
              case scrapeDoneEvent:
                ScrapeResults subResults = new ScrapeResults.fromJsObject(
                    e.message[messageFieldData]);
                _log.info("Scrape done event received, adding results (${subResults
                    .results.length}) to queue");
                total += subResults.results.length;
                toDownload.insertAll(0, subResults.results);
                _log.info("Closing tab: ${subResults.tabId}");
                p.postMessage({messageFieldCommand: closeTabCommand, messageFieldTabId: subResults.tabId});
                break;
              case fileDownloadedEvent:
                _log.info("File downloaded event received");
                // Great, continue to the next file
              break;
              default:
                throw new Exception("Unupported event: $event");
            }
          }
          loaded++;
          this.progress = ((loaded/total)*100).round();
          if(toDownload.isNotEmpty) {
            _log.info("Getting next item from queue");
            r = toDownload.removeAt(0);
            _sendMessageForScrapeResult(p, r);
          }
        }
      } finally {
        p.disconnect();
      }
    } catch(e,st) {
      _log.severe("downloadButtonClick",e,st);
    }

  }

  Future<Null> _sendMessageForScrapeResult(chrome.Port p, ScrapeResult r) {
    if(r.type==ResultTypes.page) {
      _log.fine("Item is of type page, opening page to scrape");
      p.postMessage({messageFieldCommand: openTabCommand, messageFieldUrl: r.url});
    } else {
      _log.fine("Downloading item: ${r.url}");
      p.postMessage({messageFieldCommand: downloadCommand,
        messageFieldUrl: r.url,
        messageFieldFilename: r.filename,
        //messageFieldHeaders: []
      });
    }
  }

 Future<Null> refresh() async {
      loaded = false;
     ScrapeResults results = await _scraper.getScrapeResults(window.location.href);
     if(results==null) {
       _log.warning("Null scrape results received");
     } else {
       this.results = results;
       loaded = true;
     }
 }
  Future<Null> ngOnInit() async {
    _log.fine("AppComponent.ngOnInit start");
    try {
      //refresh();
    } catch(e,st) {
      _log.severe("AppComponent.ngOnInit error", e, st);
    } finally {
      _log.fine("AppComponent.ngOnInit end");
    }
  }
}
