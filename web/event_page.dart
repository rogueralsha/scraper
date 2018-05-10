import 'dart:js';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:scraper/globals.dart';
import 'package:angular/angular.dart';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

final _log = new Logger("event_page.dart");

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(new LogPrintHandler());

  chrome.runtime.onConnect.listen((chrome.Port p) async {
    _log.info("Connection opening: ${p.name}");
    StreamSubscription messageSub;
    StreamSubscription disconnectSub;

    disconnectSub = p.onDisconnect.listen((dynamic) {
      messageSub.cancel();
      disconnectSub.cancel();
      p.disconnect();
    });

    messageSub = p.onMessage.listen((chrome.OnMessageEvent e) async {
      _log.info("Mesage received");
      JsObject message = e.message;
      _log.info(context['JSON'].callMethod('stringify',[message]));
      String command = message["command"];
      _log.info("Command received: ${command}");
      _log.info("Sender ${p.sender}");
      _log.info("Sender tab ${p.sender?.tab?.id}");
      _log.info("Sender window ${p?.sender?.tab?.windowId}");
    _log.fine("Command switch");
      switch (command) {
        case scrapePageCommand:
          await scrapePage(
              p, p.sender?.tab?.windowId, message[messageFieldTabId]??p.sender?.tab?.id, message[messageFieldUrl]);
          break;
        case openTabCommand:

          Map result =
              await _openTab(message[messageFieldUrl], p.sender?.tab?.windowId);
          _log.info("Sending response");
          _log.info(result);
          p.postMessage(result);
          break;
        case getTabIdCommand:
          _log.info("Current tab Id requested, returning ${p.sender.tab.id}");
          p.postMessage({messageFieldTabId: p.sender.tab.id});
          break;
        case closeTabCommand:
          await closeTab(p.sender.tab.windowId, message[messageFieldTabId]);
          break;
        case downloadCommand:
          int id = await chrome.downloads.download(new chrome.DownloadOptions(
              url: message[messageFieldUrl],
              filename: message[messageFieldFilename],
              conflictAction: chrome.FilenameConflictAction.UNIQUIFY,
              method: chrome.HttpMethod.GET,
              headers: message[messageFieldHeaders]));
          _log.info("Download created: $id");
          p.postMessage({messageFieldEvent: fileDownloadedEvent });
          break;
        default:
          throw new Exception("Message command not recognized: $command");
      }
    });
  });
  chrome.runtime.onMessage.listen((chrome.OnMessageEvent e) async {
    _log.info("Message received");
    _log.info(context['JSON'].callMethod('stringify',[e.message]));
    Map message = e.message;
    String command = message[messageFieldCommand];
    _log.info("Message command: $command");
    switch (command) {
      case closeTabMessageEvent:
        await closeTab(e.sender.tab.windowId, message[messageFieldTabId]);
        break;
      default:
        throw new Exception("Message command not known: $command");
    }
  });
}

Future<Null> closeTab(int windowId, int tabId) async {
  chrome.Tab tab = await determineTab(
      windowId, tabId);
  _log.info("Closing tab ${tab.id}");
  await chrome.tabs.remove(tab.id);
}

Future<Null> scrapePage(chrome.Port sourcePort, int windowId, int tabId, String url) async {
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
      _log.info(context['JSON'].callMethod('stringify',[tabE.message]));
      sourcePort.postMessage(tabE.message);
      if (tabE.message == endMessageEvent) {
        _log.info("End message event received, disconnecting");
        break;
      }
    }
  } finally {
    tabPort.disconnect();
  }

  _log.fine("scrapePage() end");
}

Future<Map> _openTab(String url, int windowId) async {
  _log.fine("openTab($url, $windowId) start");
  try {
    Map output = {messageFieldEvent: tabLoadedMessageEvent};
    chrome.Tab tab = await chrome.tabs.create(
        new chrome.TabsCreateParams(
            url: url, active: false, windowId: windowId));
    _log.info("Tab created: ${tab.id}");
    _log.info("Waiting for tab to finish loading");
    await for(chrome.OnUpdatedEvent updatedEvent in chrome.tabs.onUpdated) {
      if (updatedEvent.tabId == tab.id &&
          updatedEvent.changeInfo["status"] == "complete") {
        _log.info("New tab open complete: ${updatedEvent.tabId}");
        output[messageFieldTabId] = updatedEvent.tabId;
        break;
      }
    }
    return output;
  } finally {
    _log.fine("openTab($url, $windowId) end");
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
    chrome.TabsQueryParams params =
        new chrome.TabsQueryParams();
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
