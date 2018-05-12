import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:js';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'globals.dart';
import 'services/page_stream_service.dart';
import 'services/scraper_service.dart';
import 'services/settings_service.dart';
import 'src/todo_list/todo_list_component.dart';

// AngularDart info: https://webdev.dartlang.org/angular
// Components info: https://webdev.dartlang.org/components

@Component(
  selector: 'results-viewer',
  styleUrls: ['results_component.css'],
  templateUrl: 'results_component.html',
  directives: [TodoListComponent, NgFor, materialDirectives, NgIf],
  providers: [
    const ClassProvider(ScraperService),
    const ClassProvider(SettingsService),
    const ClassProvider(PageStreamService),
    materialProviders
  ],
)
class ResultsComponent implements OnInit {
  static final RegExp _urlMatcherRegex =
      new RegExp("^https?:\\/\\/(.+)\$", caseSensitive: false);

  final _log = new Logger("ResultsComponent");
  bool showSpinner = false;
  bool showProgress = false;
  bool savePath = false;
  bool showPopup = false;
  String artistPath = "";
  int progressPercent = 0;
  int progressMax = 0;
  int progressCurrent = 0;

  List<RelativePosition> tooltipPosition = [RelativePosition.AdjacentLeft];

  List<LinkInfo> links = <LinkInfo>[];
  List<String> availablePathPrefixes = [];

  final SettingsService _settings;

  final PageStreamService _pageStream;

  PageInfo results = new PageInfo(-1);

  ResultsComponent(this._pageStream, this._settings);
  String get artistDisplay => "${results.artist} (${links.length})";

  bool get hasError => (results?.error ?? "").isNotEmpty;

  bool get loaded => links?.isNotEmpty ?? false;
// Nothing here yet. All logic is in TodoListComponent.

  String get pathDisplay => "Path: $artistPath";

  void addResult(LinkInfo result) {
    String matchedLink = _urlMatcherRegex.firstMatch(result.url).group(1);
    for (int i = 0; i < this.links.length; i++) {
      String matchedOtherLink =
          _urlMatcherRegex.firstMatch(this.links[i].url).group(1);

      if (matchedLink == matchedOtherLink) {
        _log.info("Duplicate URL, skipping");
        return;
      }
    }
    this.links.add(result);
  }

  void closeButtonClick() async {
    try {
      closeTab();
    } catch (e, st) {
      _log.severe("closeButtonClick", e, st);
    }
  }

  void downloadButtonClick(bool close) async {
    _log.finest("downloadButtonClick($close) start");
    try {
      showSpinner = true;
      showProgress = true;
      List<LinkInfo> toDownload =
          new List<LinkInfo>.from(links.where((LinkInfo r) => r.select));

      if (toDownload.isEmpty) {
        _log.info("Nothing to download, ending");
        return;
      }

      String pathPrefix = "";
      if ((artistPath?.trim() ?? "").isNotEmpty) {
        pathPrefix = artistPath.trim();
        _log.info("Path is not null, using $pathPrefix");
        if (savePath) {
          await _settings.setMapping(results.artist, artistPath);
        }
      } else {
        if (!window.confirm("No path specified, continue?")) {
          return;
        }
      }

      this.progressMax = toDownload.length;
      this.progressCurrent = 0;

      chrome.Port p = chrome.runtime.connect(
          null, new chrome.RuntimeConnectParams(name: new Uuid().v4()));
      try {
        _log.info("Getting first item from queue");

        LinkInfo r = toDownload.removeAt(0);

        // This resets every time a new page source is processed, so that when we received multiple links from the same page they are inserted sequentially, instead of like a stack.
        int insertPosition = 0;

        _sendMessageForScrapeResult(p, r, pathPrefix);
        await for (chrome.OnMessageEvent e in p.onMessage) {
          _log.info("Message received during download process");
          _log.finer(context['JSON'].callMethod('stringify', [e.message]));

          if (e.message.hasProperty(messageFieldEvent)) {
            String event = e.message[messageFieldEvent];
            _log.finest("Event received: $event");
            switch (event) {
              case tabLoadedMessageEvent:
                // Indicates that the page had a sub page
                _log.info("Tab loaded (${e
                    .message[messageFieldTabId]}) event received, sending scrape signal to page");
                // Send a message to the event page to subscribe to the new page's scraping
                p.postMessage({
                  messageFieldCommand: subscribeCommand,
                  messageFieldTabId: e.message[messageFieldTabId]
                });
                // Ask the page to start scraping
                p.postMessage({
                  messageFieldCommand: startScrapeCommand,
                  messageFieldTabId: e.message[messageFieldTabId]
                });
                continue;
              case pageInfoEvent:
                // We don't do anything with this right now
                continue;
              case linkInfoEvent:
                _log.finest("Link info received, adding to queue");
                LinkInfo li =
                    new LinkInfo.fromJson(e.message[messageFieldData]);
                toDownload.insert(insertPosition, li);
                if(insertPosition>0) {
                  progressMax++;
                }
                insertPosition++;
                _log.finest("Queue length: ${toDownload.length}");
                continue;
              case scrapeDoneEvent:
                _log.info(
                    "Ubsubscribing from tab: ${e.message[messageFieldTabId]}");
                p.postMessage({
                  messageFieldCommand: unsubscribeCommand,
                  messageFieldTabId: e.message[messageFieldTabId]
                });
                _log.info("Closing tab: ${e.message[messageFieldTabId]}");
                p.postMessage({
                  messageFieldCommand: closeTabCommand,
                  messageFieldTabId: e.message[messageFieldTabId]
                });
                break;
              case fileDownloadedEvent:
                _log.info("File downloaded event received");
                // Great, continue to the next file
                break;
              default:
                throw new Exception("Unupported event: $event");
            }
          if(event!=scrapeDoneEvent||insertPosition==0) {
            progressCurrent++;
          }
          this.progressPercent =
              ((progressCurrent / progressMax) * 100).round();
          if (toDownload.isNotEmpty) {
            insertPosition = 0;
            _log.info("Getting next item from queue");
            r = toDownload.removeAt(0);
            _sendMessageForScrapeResult(p, r, pathPrefix);
          } else {
            break;
          }
          }

        }
        if (close) {
          closeTab();
        }
      } finally {
        p.disconnect();
      }
    } catch (e, st) {
      _log.severe("downloadButtonClick($close)", e, st);
    } finally {
      showSpinner = false;
      showProgress = false;
      _log.finest("downloadButtonClick($close) end");
    }
  }

  Future<Null> ngOnInit() async {
    _log.finest("AppComponent.ngOnInit start");
    try {
      _pageStream.onPageInfo.listen((PageInfo pi) async {
        _log.info("PageInfo received, updating component data");
        this.results = pi;
        savePath = results.saveByDefault;
        artistPath = await _settings.getMapping(results.artist);
        availablePathPrefixes = await _settings.getAvailablePrefixes();
      });
      _pageStream.onLinkInfo.listen((LinkInfo li) {
        _log.info("LinkInfo received, updating component data");
        this.addResult(li);
      });
      if (!document.hidden) {
        await _pageStream.requestScrapeStart();
      } else {
        // ignore: unawaited_futures
        document.onVisibilityChange.firstWhere((Event e) {
          return !document.hidden;
        }).then((e) {
          {
            _pageStream.requestScrapeStart();
          }
        });
      }
    } catch (e, st) {
      _log.severe("AppComponent.ngOnInit error", e, st);
    } finally {
      _log.finest("AppComponent.ngOnInit end");
    }
  }

  Future<Null> openAllButtonClick(bool waitForLoad) async {
    try {
      showSpinner = true;
      showProgress = true;
      Queue<LinkInfo> toOpen =
          new Queue<LinkInfo>.of(links.where((LinkInfo r) => r.select));

      if (toOpen.isEmpty) {
        _log.info("Nothing to open, ending");
        return;
      }

      this.progressMax = toOpen.length;
      this.progressCurrent = 0;

      _log.info("Wait is set to $waitForLoad");

      chrome.Port p = chrome.runtime.connect(
          null, new chrome.RuntimeConnectParams(name: new Uuid().v4()));
      try {
        if (waitForLoad) {
          LinkInfo r = toOpen.removeFirst();
          p.postMessage(
              {messageFieldCommand: openTabCommand, messageFieldUrl: r.url});

          await for (chrome.OnMessageEvent e in p.onMessage) {
            if (e.message == endMessageEvent) {
              break;
            }
            this.progressCurrent++;
            this.progressPercent =
                ((this.progressCurrent / this.progressMax) * 100).round();
            if (waitForLoad && toOpen.isNotEmpty) {
              LinkInfo r = toOpen.removeFirst();
              p.postMessage({
                messageFieldCommand: openTabCommand,
                messageFieldUrl: r.url
              });
            }
          }
        } else {
          while (toOpen.isNotEmpty) {
            LinkInfo r = toOpen.removeFirst();
            p.postMessage(
                {messageFieldCommand: openTabCommand, messageFieldUrl: r.url});
          }
        }
      } finally {
        p.disconnect();
      }
    } catch (e, st) {
      _log.severe("openAllButtonClick", e, st);
    } finally {
      showSpinner = false;
      showProgress = false;
    }
  }

  void openTab(MouseEvent e, String url) {
    e.preventDefault();
    chrome.runtime.sendMessage(
        {messageFieldCommand: openTabCommand, messageFieldUrl: url});
  }

  Future<Null> refreshButtonClick() async {
    try {
      results = new PageInfo(-1);
      links.clear();
      savePath = false;
      artistPath = "";
      availablePathPrefixes = [];
      await _pageStream.requestScrapeStart();
    } catch (e, st) {
      _log.severe("refreshButtonClick", e, st);
    }
  }

  void selectAbove(int i) {
    for (int j = 0; j < links.length; j++) {
      links[j].select = (j <= i);
    }
  }

  void selectBeneath(int i) {
    for (int j = 0; j < links.length; j++) {
      links[j].select = (j >= i);
    }
  }

  void selectOnly(int i) {
    for (int j = 0; j < links.length; j++) {
      links[j].select = (i == j);
    }
  }

  void _sendMessageForScrapeResult(
      chrome.Port p, LinkInfo r, String prefixPath) {
    if (r.type == LinkType.page) {
      _log.fine("Item is of type page, opening page to scrape");
      p.postMessage(
          {messageFieldCommand: openTabCommand, messageFieldUrl: r.url});
    } else {
      StringBuffer pathBuffer = new StringBuffer();
      if (prefixPath.isNotEmpty) {
        pathBuffer.write(prefixPath);
        pathBuffer.write("/");
      }
      pathBuffer.write(r.filename);
      String fullPath = pathBuffer.toString();

      _log.fine("Downloading item: ${r.url} to $fullPath");
      p.postMessage({
        messageFieldCommand: downloadCommand,
        messageFieldUrl: r.url,
        messageFieldFilename: fullPath,
        //TODO: Get redirect headers up and running
        //messageFieldHeaders: []
      });
    }
  }
}
