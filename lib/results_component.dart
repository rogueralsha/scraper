import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:io';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'globals.dart';
import 'services/page_stream_service.dart';
import 'services/scraper_service.dart';
import 'services/settings_service.dart';

// AngularDart info: https://webdev.dartlang.org/angular
// Components info: https://webdev.dartlang.org/components

@Component(
  selector: 'results-viewer',
  styleUrls: <String>['results_component.css'],
  templateUrl: 'results_component.html',
  directives: [NgFor, materialDirectives, NgIf],
  providers: [
    const ClassProvider(ScraperService),
    const ClassProvider(SettingsService),
    const ClassProvider(PageStreamService),
    materialProviders
  ],
)
class ResultsComponent implements OnInit, OnDestroy {
  static final RegExp _urlMatcherRegex =
      new RegExp(r"^https?://(.+)$", caseSensitive: false);

  static final Logger _log = new Logger("ResultsComponent");
  bool showProgress = false;
  bool savePath = false;
  bool promptForDownload = false;
  bool showPopup = false;
  bool disableInterface = false;
  String artistPath = "";
  int progressPercent = 0;
  int progressMax = 0;
  int progressCurrent = 0;

  List<RelativePosition> tooltipPosition = [RelativePosition.AdjacentLeft];
  List<LinkInfo> links = <LinkInfo>[];

  List<String> availablePathPrefixes = [];

  final SettingsService _settings;
  final PageStreamService _pageStream;

  PageInfo results = new PageInfo("none", "", -1);

  bool get showLoadAllButton => loaded && results.incrementalLoader;

  ResultsComponent(this._pageStream, this._settings);

  String get artistDisplay =>
      "${results.artist} ($selectedLinkCount/$linkCount)";

  bool get hasError => (results?.error ?? "").isNotEmpty;

  int get linkCount => links.length;
  bool get loaded => links?.isNotEmpty ?? false;

  String get pathDisplay => "Path: $artistPath";

  int get selectedLinkCount => links.where((LinkInfo r) => r.select).length;
// Nothing here yet. All logic is in TodoListComponent.

  List<LinkInfo> get selectedLinks =>
      new List<LinkInfo>.from(links.where((LinkInfo r) => r.select));

  void addResult(LinkInfo result) {
    final String matchedLink = _urlMatcherRegex.firstMatch(result.url).group(1);
    for (int i = 0; i < this.links.length; i++) {
      final String matchedOtherLink =
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
    } on Exception catch (e, st) {
      _log.severe("closeButtonClick", e, st);
    }
  }

  int _pendingScrapes = 0;

  void downloadButtonClick(dynamic event, bool close) async {
    _log.finest("downloadButtonClick($event, $close) start");

    try {
      showProgress = true;
      disableInterface = true;
      bool cancelClose = false;
      final List<LinkInfo> toDownload =
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
      } else if (!promptForDownload) {
        if (!window.confirm("No path specified, continue?")) {
          return;
        }
      }

      if (savePath) {
        final SourceArtistSetting sourceArtistSetting = await _settings
            .getSourceArtistSettings(results.source, results.artist)
          ..promptForDownload = promptForDownload;
        await _settings.setSourceArtistSettings(
            results.source, results.artist, sourceArtistSetting);
      }

      int maxConcurrentDownloads = await _settings.getMaxConcurrentDownloads();
      if (promptForDownload) maxConcurrentDownloads = 1;

      _log.info("Max concurrent downloads is set to $maxConcurrentDownloads");
      int concurrentDownloads = 0;

      this.progressMax = toDownload.length;
      this.progressCurrent = 0;
      _pendingScrapes = 0;

      final String downloadPathPrefix = await _settings.getDownloadPathPrefix();
      if ((downloadPathPrefix?.trim() ?? "").isNotEmpty) {
        if (pathPrefix.isEmpty) {
          pathPrefix = downloadPathPrefix;
        } else {
          pathPrefix = "$downloadPathPrefix/$pathPrefix";
        }
      }

      _log.info("Final download path: $pathPrefix");

      final chrome.Port p = chrome.runtime.connect(
          null, new chrome.RuntimeConnectParams(name: new Uuid().v4()));
      try {
        _log.info("Getting first item from queue");

        LinkInfo r = toDownload.removeAt(0);

        // This resets every time a new page source is processed, so that when we received multiple links from the same page they are inserted sequentially, instead of like a stack.
        int insertPosition = 0;

        _sendMessageForScrapeResult(p, r, pathPrefix);
        if (close)
          chrome.runtime.sendMessage({messageFieldCommand: nextTabCommand});

        await for (chrome.OnMessageEvent e in p.onMessage) {
          this.progressPercent =
              ((progressCurrent / progressMax) * 100).round();

          _log
            ..info("Message received during download process")
            ..finer(jsVarDump(e.message));

          if (e.message.hasProperty(messageFieldEvent)) {
            final String event = e.message[messageFieldEvent];
            _log.finest("Event received: $event");
            switch (event) {
              case tabLoadedMessageEvent:
                // Indicates that the page had a sub page
                _log.info("Tab loaded (${e
                    .message[messageFieldTabId]}) event received, sending scrape signal to page");
                // Send a message to the event page to subscribe to the new page's scraping
                p.postMessage({
                  messageFieldCommand: subscribeCommand,
                  messageFieldTabId: e.message[messageFieldTabId],
                });
                // Ask the page to start scraping
                p.postMessage({
                  messageFieldCommand: startScrapeCommand,
                  messageFieldTabId: e.message[messageFieldTabId],
                  messageFieldUrl: e.message[messageFieldUrl]
                });
                continue;
              case pageInfoEvent:
                // We don't do anything with this right now
                continue;
              case linkInfoEvent:
                _log.finest("Link info received, adding to queue");
                final LinkInfo li =
                    new LinkInfo.fromJson(e.message[messageFieldData]);
                toDownload.insert(insertPosition, li);
                if (insertPosition > 0) {
                  progressMax++;
                }
                insertPosition++;
                _log.finest("Queue length: ${toDownload.length}");
                continue;
              case scrapeDoneEvent:
                _pendingScrapes--;
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
              case fileDownloadStartEvent:
                _log.info("File download start event received");
                concurrentDownloads++;
                break;
              case fileDownloadCompleteEvent:
                _log.info("File download complete event received");
                concurrentDownloads--;
                progressCurrent++;
                break;
              case fileDownloadErrorEvent:
                _log.info("File download error event received");
                window.alert(
                    "An error occurred for download ${e.message[messageFieldDownloadId]}: ${e?.message[messageFieldError]??'Unknown error'}");
                //throw new Exception(
                //"An error occurred for download ${e.message[messageFieldDownloadId]}: ${e?.message[messageFieldError]??'Unknown error'}");
                concurrentDownloads--;
                progressCurrent++;
                cancelClose = true;
                break;
              default:
                throw new Exception("Unupported event: $event");
            }

            this.progressPercent =
                ((progressCurrent / progressMax) * 100).round();
            _log
              ..finer("Progress is currently at $progressCurrent/$progressMax")
              ..finer(
                  "Concurrent downloads at $concurrentDownloads/$maxConcurrentDownloads")
              ..finer("Pending scrapes at $_pendingScrapes");
            if (concurrentDownloads >= maxConcurrentDownloads) {
              continue;
            }
            if (toDownload.isNotEmpty) {
              insertPosition = 0;
              _log.finer("Getting next item from queue");
              r = toDownload.removeAt(0);
              _sendMessageForScrapeResult(p, r, pathPrefix);
            } else if (concurrentDownloads == 0 && _pendingScrapes == 0) {
              break;
            }
          }
        }
        if (close && !cancelClose) {
          _log.finest("Close tab specified, closing tab");
          closeTab();
        }
      } finally {
        p.disconnect();
      }
    } on Exception catch (e, st) {
      _log.severe("downloadButtonClick($close)", e, st);
    } finally {
      showProgress = false;
      disableInterface = false;
      _log.finest("downloadButtonClick($close) end");
    }
  }

  StreamSubscription<KeyEvent> keyboardSubscription;

  @override
  Future<Null> ngOnDestroy() async {
    await keyboardSubscription?.cancel();
  }

  @override
  Future<Null> ngOnInit() async {
    _log.finest("AppComponent.ngOnInit start");
    try {
      _pageStream.onPageInfo.listen((PageInfo pi) async {
        if(pi.sourceUrl==window.location.toString()) {
          _log.info("PageInfo received, updating component data");
          this.results = pi;
          this.savePath = results.saveByDefault;
          this.promptForDownload = results.promptForDownload;
          this.artistPath = await _settings.getMapping(results.artist);
          this.availablePathPrefixes = await _settings.getAvailablePrefixes();
        } else {
        _log.info("PageInfo received, appears to be from iframe: ${pi.sourceUrl}");
        }
      });
      _pageStream.onLinkInfo.listen((LinkInfo li) {
        _log.info("LinkInfo received, updating component data");
        this.addResult(li);
      });
      keyboardSubscription = window.onKeyUp.listen(onKeyboardEvent);

      if (!document.hidden) {
        await _pageStream.requestScrapeStart();
      } else {
        // ignore: unawaited_futures
        document.onVisibilityChange
            .firstWhere((Event e) => !document.hidden)
            .then((e) {
          {
            _pageStream.requestScrapeStart();
          }
        });
      }
    } on Exception catch (e, st) {
      _log.severe("AppComponent.ngOnInit error", e, st);
    } finally {
      _log.finest("AppComponent.ngOnInit end");
    }
  }

  void onKeyboardEvent(KeyEvent e) {
    if (disableInterface || !e.ctrlKey) return;
    switch (e.keyCode) {
      case KeyCode.DELETE:
        closeButtonClick();
        break;
      case KeyCode.DOWN:
        downloadButtonClick(null, !e.altKey);
        break;
      case KeyCode.UP:
        openAllButtonClick(e.altKey);
        break;
    }
  }

  Future<Null> openAllButtonClick(bool waitForLoad) async {
    try {
      showProgress = true;
      disableInterface = true;
      final Queue<LinkInfo> toOpen =
          new Queue<LinkInfo>.of(links.where((LinkInfo r) => r.select));

      if (toOpen.isEmpty) {
        _log.info("Nothing to open, ending");
        return;
      }

      this.progressMax = toOpen.length;
      this.progressCurrent = 0;

      _log.info("Wait is set to $waitForLoad");

      final chrome.Port p = chrome.runtime.connect(
          null, new chrome.RuntimeConnectParams(name: new Uuid().v4()));
      try {
        if (waitForLoad) {
          final LinkInfo r = toOpen.removeFirst();
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
              final LinkInfo r = toOpen.removeFirst();
              p.postMessage({
                messageFieldCommand: openTabCommand,
                messageFieldUrl: r.url
              });
            }
          }
        } else {
          while (toOpen.isNotEmpty) {
            final LinkInfo r = toOpen.removeFirst();
            p.postMessage(
                {messageFieldCommand: openTabCommand, messageFieldUrl: r.url});
          }
        }
      } finally {
        p.disconnect();
      }
    } on Exception catch (e, st) {
      _log.severe("openAllButtonClick", e, st);
    } finally {
      showProgress = false;
      disableInterface = false;
    }
  }

  void openTab(MouseEvent e, String url) {
    e.preventDefault();
    chrome.runtime.sendMessage(
        {messageFieldCommand: openTabCommand, messageFieldUrl: url});
  }

  Future<Null> refreshButtonClick() async {
    try {
      results = new PageInfo("none", "", -1);
      links.clear();
      savePath = false;
      artistPath = "";
      availablePathPrefixes = [];
      await _pageStream.requestScrapeStart();
    } on Exception catch (e, st) {
      _log.severe("refreshButtonClick", e, st);
    }
  }

  void selectAbove(int i) {
    for (int j = 0; j < links.length; j++) {
      links[j].select = j <= i;
    }
  }

  void selectBeneath(int i) {
    for (int j = 0; j < links.length; j++) {
      links[j].select = j >= i;
    }
  }

  void selectOnly(int i) {
    for (int j = 0; j < links.length; j++) {
      links[j].select = i == j;
    }
  }

  void _sendMessageForScrapeResult(
      chrome.Port p, LinkInfo r, String prefixPath) {
    if (r.type == LinkType.page) {
      _log.fine("Item is of type page, opening page to scrape");
      _pendingScrapes++;
      p.postMessage(
          {messageFieldCommand: openTabCommand, messageFieldUrl: r.url});
    } else {
      final StringBuffer pathBuffer = new StringBuffer();
      if (prefixPath.isNotEmpty) {
        pathBuffer..write(prefixPath)..write("/");
      }
      pathBuffer.write(r.filename);
      String fullPath = pathBuffer.toString();
      while(fullPath.contains("//")) {
        fullPath = fullPath.replaceAll("//","/");
      }

      _log.fine("Downloading item: ${r.url} to $fullPath");
      final Map<String, dynamic> data = <String, dynamic>{
        messageFieldCommand: downloadCommand,
        messageFieldUrl: r.url,
        messageFieldPrompt: promptForDownload
      };
      //if (promptForDownload) {
      //data[messageFieldFilename] = r.filename;
      //} else {
      data[messageFieldFilename] = fullPath;
      //}

      if (r.referrer?.isNotEmpty ?? false) {
        _log.finest("Referrer is not empty, sending as header ${r.referrer}");
        data[messageFieldHeaders] = <String, String>{
          HttpHeaders.REFERER: r.referrer
        };
      }
      p.postMessage(data);
    }
  }

  Future<Null> loadAllItems() async {
    _log.finest("loadAllItems()");
    await _pageStream.requestLoadWholePage();
  }
}
