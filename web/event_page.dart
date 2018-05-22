import 'dart:js';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:scraper/globals.dart';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:scraper/services/settings_service.dart';

final Logger _log = new Logger("event_page.dart");

SettingsService settings = new SettingsService();

Future<Null> main() async {
  Logger.root.level = await settings.getLoggingLevel();
  Logger.root.onRecord.listen(new LogPrintHandler());
  _log.info("Logging set to ${Logger.root.level.name}");

  chrome.runtime.onConnect.listen((chrome.Port p) async {
    _log.info("Connection opening: ${p.name}");
    StreamSubscription messageSub;
    StreamSubscription disconnectSub;

    disconnectSub = p.onDisconnect.listen((dynamic) async {
      await messageSub.cancel();
      await disconnectSub.cancel();
      p.disconnect();
    });

    messageSub = p.onMessage.listen((chrome.OnMessageEvent e) async {
      _log.info("Mesage received");
      JsObject message = e.message;
      _log.finer(context['JSON'].callMethod('stringify', [message]));
      _log.fine("Sender ${p.sender}");
      _log.fine("Sender tab ${p.sender?.tab?.id}");
      _log.fine("Sender window ${p?.sender?.tab?.windowId}");

      if (message.hasProperty(messageFieldCommand)) {
        String command = message["command"];
        _log.info("Command received: ${command}");
        _log.fine("Command switch");
        switch (command) {
          case scrapePageCommand:
            await scrapePage(
                p,
                p.sender?.tab?.windowId,
                message[messageFieldTabId] ?? p.sender?.tab?.id,
                message[messageFieldUrl]);
            break;
          case openTabCommand:
            Map result = await _openTab(
                message[messageFieldUrl], p.sender?.tab?.windowId);
            _log.info("Sending response");
            _log.info(result);
            p.postMessage(result);
            break;
          case getTabIdCommand:
            _log.info("Current tab Id requested, returning ${p.sender.tab.id}");
            p.postMessage(
                <String, dynamic>{messageFieldTabId: p.sender.tab.id});
            break;
          case closeTabCommand:
            await closeTab(p.sender.tab.windowId, message[messageFieldTabId]);
            break;
          case downloadCommand:
            String path = message[messageFieldFilename];
            if (path.startsWith("/"))
              path = path.substring(1);
            path = path.replaceAll("//", "/").replaceAll(":", "_");
            _log.info("Final path: $path");

            final int id = await chrome.downloads.download(new chrome.DownloadOptions(
                url: message[messageFieldUrl],
                filename: path,
                conflictAction: chrome.FilenameConflictAction.UNIQUIFY,
                method: chrome.HttpMethod.GET,
                headers: message[messageFieldHeaders]));
            _log.info("Download created: $id");

            p.postMessage({messageFieldEvent: fileDownloadStartEvent, messageFieldDownloadId: id });

            await for(chrome.DownloadDelta dd in chrome.downloads.onChanged.where((chrome.DownloadDelta dd) =>dd.id==id)) {
              if(dd.state!=null) {
                switch(dd.state.current) {
                  case "interrupted":
                    final List<chrome.DownloadItem> items = await chrome.downloads.search(new chrome.DownloadQuery(id:id));
                    String error;
                    if(items.isNotEmpty) {
                      chrome.DownloadItem item = items.first;
                      error = item.error.toString();
                    }
                    p.postMessage({messageFieldEvent: fileDownloadErrorEvent, messageFieldDownloadId: id, messageFieldError: error });
                    return;
                  case "complete":
                    p.postMessage({messageFieldEvent: fileDownloadCompleteEvent, messageFieldDownloadId: id });
                    return;
                }
              }
            }
            break;
          case subscribeCommand:
            subscribeToPage(p, message[messageFieldTabId]);
            break;
          case unsubscribeCommand:
            await unsubscribeFromPage(p, message[messageFieldTabId]);
            break;
          case startScrapeCommand:
            await chrome.tabs.sendMessage(message[messageFieldTabId],
                {messageFieldCommand: startScrapeCommand, messageFieldUrl: message[messageFieldUrl]});
            break;
          default:
            throw new Exception("Message command not recognized: $command");
        }
      } else if (message.hasProperty(messageFieldEvent)) {
      } else {
        throw new Exception("Unknown message received");
      }
    });
  });
  chrome.runtime.onMessage.listen((chrome.OnMessageEvent e) async {
    try {
      _log.info("Message received");
      _log.fine(context['JSON'].callMethod('stringify', [e.message]));
      JsObject message = e.message;
      if (message.hasProperty(messageFieldCommand)) {
        String command = message[messageFieldCommand];
        _log.info("Message command: $command");
        switch (command) {
          case closeTabCommand:
            await closeTab(e.sender.tab.windowId,
                message[messageFieldTabId] ?? e.sender.tab.id);
            break;
          case openTabCommand:
            await _openTab(message[messageFieldUrl], e.sender?.tab?.windowId);
            break;
          default:
            throw new Exception("Message command not known: $command");
        }
      } else if (message.hasProperty(messageFieldEvent)) {
        String event = message[messageFieldEvent];
        _log.info("Message event: $event");
        switch (event) {
          case pageInfoEvent:
          case linkInfoEvent:
          case scrapeDoneEvent:
            _log.info("Sending data to PageUpdateEvent");
            PageUpdateEvent pageUpdateEvent =
                new PageUpdateEvent(e.sender.tab.id, e.message);
            _pageSubscriptionController.add(pageUpdateEvent);
            break;
          default:
            throw new Exception("Message event not known: $event");
        }
      } else {
        throw new Exception("Unknow message format");
      }
    } finally {
      //(e.sendResponse as JsFunction).apply(["response"]);
    }
  });
}

class PageUpdateEvent {
  int tabId;
  dynamic data;
  PageUpdateEvent(this.tabId, this.data);
}

Stream<PageUpdateEvent> get onPageSubscriptionUpdate =>
    _pageSubscriptionController.stream;
StreamController<PageUpdateEvent> _pageSubscriptionController =
    new StreamController<PageUpdateEvent>.broadcast();

final Map<String, Map<int, StreamSubscription>> pageSubscriptions =
    <String, Map<int, StreamSubscription>>{};

Future<Null> unsubscribeFromPage(chrome.Port p, int tabId) async {
  if (pageSubscriptions.containsKey(p.name) &&
      pageSubscriptions[p.name].containsKey(tabId)) {
    _log.fine("Unsubscribing port ${p.name} from tab $tabId");
    await pageSubscriptions[p.name][tabId].cancel();
    pageSubscriptions[p.name].remove(tabId);
  } else {
    _log.warning("Port ${p.name} does not have a subscription to tab $tabId");
  }
}

void subscribeToPage(chrome.Port p, int tabId) {
  StreamSubscription pageSub;
  pageSub = onPageSubscriptionUpdate.listen((PageUpdateEvent e) {
    if (tabId == e.tabId) {
      _log.info(
          "Page update tab id matches subscription, forwarding to listener");
      p.postMessage(e.data);
    }
  });
  if (!pageSubscriptions.containsKey(p.name)) {
    pageSubscriptions[p.name] = <int, StreamSubscription>{};
  }
  pageSubscriptions[p.name][tabId] = pageSub;
  // ignore: unawaited_futures
  p.onDisconnect.first.then((e) async {
    await pageSub.cancel();
    pageSubscriptions[p.name].remove(tabId);
  });
}

Future<Null> closeTab(int windowId, int tabId) async {
  chrome.Tab tab = await determineTab(windowId, tabId);
  _log.info("Closing tab ${tab.id}");
  await chrome.tabs.remove(tab.id);
}

Future<Null> scrapePage(
    chrome.Port sourcePort, int windowId, int tabId, String url) async {
  final chrome.Tab tab = await determineTab(windowId, tabId);

  _log.fine("Connecting to tab ${tab.id}");
  chrome.Port tabPort = chrome.tabs
      .connect(tab.id, new chrome.TabsConnectParams(name: new Uuid().v4()));
  try {
    _log.info("Sending scrape page command to page");
    tabPort.postMessage(
        {messageFieldCommand: scrapePageCommand, messageFieldUrl: url});
    _log.info("Listening for response");
    await for (chrome.OnMessageEvent tabE in tabPort.onMessage) {
      _log.info("Message received, forwarding to page");
      _log.fine(context['JSON'].callMethod('stringify', [tabE.message]));
      sourcePort.postMessage(tabE.message);
      if (tabE.message == endMessageEvent) {
        _log.info("End message event received, disconnecting");
        break;
      }
    }
  } finally {
    tabPort.disconnect();
  }

  _log.finest("scrapePage() end");
}

Future<Map> _openTab(String url, int windowId) async {
  _log.finest("openTab($url, $windowId) start");
  try {
    Map output = {messageFieldEvent: tabLoadedMessageEvent};
    chrome.Tab tab = await chrome.tabs.create(new chrome.TabsCreateParams(
        url: url, active: false, windowId: windowId));
    _log.info("Tab created: ${tab.id}");
    _log.info("Waiting for tab to finish loading");
    await for (chrome.OnUpdatedEvent updatedEvent in chrome.tabs.onUpdated) {
      if (updatedEvent.tabId == tab.id &&
          updatedEvent.changeInfo["status"] == "complete") {
        _log.info("New tab open complete: ${updatedEvent.tabId}");
        output[messageFieldTabId] = updatedEvent.tabId;
        output[messageFieldUrl] = updatedEvent.tab.url;
        break;
      }
    }
    return output;
  } finally {
    _log.finest("openTab($url, $windowId) end");
  }
}

Future<chrome.Tab> determineTab(int windowId, int tabId) async {
  chrome.Tab tab;
  if (tabId != null) {
    _log.info("tabId is provided: ${tabId}");
    tab = await getTabById(tabId);
  } else {
    _log.info("tabId not provided, detecting current tab");
    // This is the page requesting the media from an iframe, we just forward it right back to the tab
    chrome.TabsQueryParams params = new chrome.TabsQueryParams();
    if (windowId != null) {
      _log.info("Window ID provided: $windowId");
      params.windowId = windowId;
    } else {
      params.currentWindow = true;
    }
    params.active = true;

    List<chrome.Tab> tabs = await chrome.tabs.query(params);
    if (tabs.length == 0) {
      throw new Exception("No tab candidate found");
    }
    tab = tabs[0];
  }
  _log.info("Tab found, ${tab.id}");
  return tab;
}

Future<chrome.Tab> getTabById(int tabId) async {
  List<chrome.Tab> tabs = await chrome.tabs.query(new chrome.TabsQueryParams());
  for (int i = 0; i < tabs.length; i++) {
    chrome.Tab tab = tabs[i];
    if (tab.id == tabId) {
      return tab;
    }
  }
  return null;
}
