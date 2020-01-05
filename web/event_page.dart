import 'dart:html' as html;
import 'dart:async';
import 'dart:js';

import 'package:scraper/web_extensions/web_extensions.dart' as browser;
import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'package:scraper/services/settings_service.dart';
import 'package:uuid/uuid.dart';

Future<Null> main() async {
  Logger.root.level = await settings.getLoggingLevel();
  Logger.root.onRecord.listen(logToConsole);
  _log.info("Logging set to ${Logger.root.level.name}");

  browser.runtime.onConnect.listen((browser.Port p) async {
    _log.info("Connection opening: ${p.name}");
    StreamSubscription<dynamic> messageSub;
    StreamSubscription<dynamic> disconnectSub;

    disconnectSub = p.onDisconnect.listen((dynamic e) async {
      await messageSub.cancel();
      await disconnectSub.cancel();
      p.disconnect();
    });

    messageSub = p.onMessage.listen((dynamic message) async {
      _log.info("Mesage received");
      _log
        ..finer(jsVarDump(message))
        ..fine("Sender ${p.sender}")
        ..fine("Sender tab ${p.sender?.tab?.id}")
        ..fine("Sender window ${p?.sender?.tab?.windowId}");

      if (message.hasProperty(messageFieldCommand)) {
        final String command = message["command"];
        _log.info("Command received: $command");
        switch (command) {
          case scrapePageCommand:
            await scrapePage(
                p,
                p.sender?.tab?.windowId,
                message[messageFieldTabId] ?? p.sender?.tab?.id,
                message[messageFieldUrl]);
            break;
          case openTabCommand:
            final Map result = await _openTab(
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
          case uploadCommand:
            await uploadItem(p, message);
            break;
          case downloadCommand:
            String path = message[messageFieldFilename];
            if (path.startsWith("/"))
              path = path.substring(1);
            if(path.endsWith("."))
              path = path.substring(0,path.length-1);

            path = path.replaceAll("//", "/").replaceAll(":", "_");
            _log.info("Final path: $path");


            Map headers;
            if (message[messageFieldHeaders] != null) {
              final JsObject headerObj = message[messageFieldHeaders];
              _log..finer("messageFieldHeaders:")..finer(jsVarDump(headerObj));

              headers = {"Referer": headerObj["Referer"]};

              if (headerObj["Referer"]?.toString()?.isEmpty ?? true) {
                _log.warning("Header was passed with null referrer");
              }
            }

            final int id = await browser.downloads.download(
                url: message[messageFieldUrl],
                filename: path,
                headers: headers,
                conflictAction: browser.FilenameConflictAction.uniquify,
                method: "GET",
                saveAs: message[messageFieldPrompt] ?? false);

            _log.info("Download created: $id");
            final browser.DownloadItem item = (await browser.downloads
                    .search(id:id))
                .first;

            p.postMessage({
              messageFieldEvent: fileDownloadStartEvent,
              messageFieldDownloadId: id,
              messageFieldPath: item.filename
            });

            await for (browser.DownloadDelta dd in browser.downloads.onChanged
                .where((browser.DownloadDelta dd) => dd.id == id)) {
              if (dd.state != null) {
                switch (dd.state.current) {
                  case "interrupted":
                    final List<browser.DownloadItem> items = await browser
                        .downloads
                        .search(id:id);
                    String error, path;
                    if (items.isNotEmpty) {
                      final browser.DownloadItem item = items.first;
                      error = item.error.toString();
                      path = item.filename;
                    }
                    p.postMessage(<String, dynamic>{
                      messageFieldEvent: fileDownloadErrorEvent,
                      messageFieldDownloadId: id,
                      messageFieldError: error,
                      messageFieldPath: path
                    });
                    return;
                  case "complete":
                    p.postMessage({
                      messageFieldEvent: fileDownloadCompleteEvent,
                      messageFieldDownloadId: id,
                      messageFieldPath: path
                    });
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
            await browser.tabs.sendMessage(message[messageFieldTabId], {
              messageFieldCommand: startScrapeCommand,
              messageFieldUrl: message[messageFieldUrl]
            });
            break;
          case loadWholePageCommand:
            await browser.tabs.sendMessage(message[messageFieldTabId], {
              messageFieldCommand: loadWholePageCommand,
              messageFieldUrl: message[messageFieldUrl]
            });
            break;
          default:
            throw new Exception("Message command not recognized: $command");
        }
      } else if (message.hasProperty(messageFieldEvent)) {
      } else {
        throw new Exception("Unknown message received: " + jsVarDump(message));
      }
    });
  });

  browser.runtime.onMessage.listen((browser.OnMessageEvent e) async {
    try {
      _log.info("Message received");
      _log.fine(jsVarDump(e.message));
      final JsObject message = e.message;
      if (message.hasProperty(messageFieldCommand)) {
        final String command = message[messageFieldCommand];
        _log.info("Message command: $command");
        switch (command) {
          case closeTabCommand:
            await closeTab(e.sender.tab.windowId,
                message[messageFieldTabId] ?? e.sender.tab.id);
            break;
          case openTabCommand:
            await _openTab(message[messageFieldUrl], e.sender?.tab?.windowId);
            break;
          case nextTabCommand:
            final List<browser.Tab> tabs = await browser.tabs.query(windowId:e.sender.tab.windowId);
            for (browser.Tab tab in tabs) {
              if (tab.index == (e.sender.tab.index + 1)) {
                await browser.tabs.update(tab.id, active: true);
                break;
              }
            }
            break;
          default:
            throw new Exception("Message command not known: $command");
        }
      } else if (message.hasProperty(messageFieldEvent)) {
        final String event = message[messageFieldEvent];
        _log.info("Message event: $event");
        switch (event) {
          case pageInfoEvent:
          case linkInfoEvent:
          case scrapeDoneEvent:
            _log.info("Sending data to PageUpdateEvent");
            final PageUpdateEvent pageUpdateEvent =
                new PageUpdateEvent(e.sender.tab.id, e.message);
            _pageSubscriptionController.add(pageUpdateEvent);
            break;
          case pageHealthEvent:
            return;
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

final Map<String, Map<int, StreamSubscription<PageUpdateEvent>>>
    pageSubscriptions =
    <String, Map<int, StreamSubscription<PageUpdateEvent>>>{};

SettingsService settings = new SettingsService();

final Logger _log = new Logger("event_page.dart");

StreamController<PageUpdateEvent> _pageSubscriptionController =
    new StreamController<PageUpdateEvent>.broadcast();

Stream<PageUpdateEvent> get onPageSubscriptionUpdate =>
    _pageSubscriptionController.stream;

Future<Null> closeTab(int windowId, int tabId) async {
  final browser.Tab tab = await determineTab(windowId, tabId);
  _log.info("Closing tab ${tab.id}");
  await browser.tabs.remove(tab.id);
}

Future<browser.Tab> determineTab(int windowId, int tabId) async {
  browser.Tab tab;
  if (tabId != null) {
    _log.info("tabId is provided: $tabId");
    tab = await getTabById(tabId);
  } else {
    _log.info("tabId not provided, detecting current tab");
    // This is the page requesting the media from an iframe, we just forward it right back to the tab

    List<browser.Tab> tabs;
    if (windowId != null) {
      _log.info("Window ID provided: $windowId");
      tabs = await browser.tabs.query(active: true, windowId: windowId);
    } else {
      tabs = await browser.tabs.query(active: true, currentWindow: true);
    }

    if (tabs.isEmpty) {
      throw new Exception("No tab candidate found");
    }
    tab = tabs[0];
  }
  _log.info("Tab found, ${tab.id}");
  return tab;
}

Future<browser.Tab> getTabById(int tabId) async {
  final List<browser.Tab> tabs =
      await browser.tabs.query();
  for (int i = 0; i < tabs.length; i++) {
    final browser.Tab tab = tabs[i];
    if (tab.id == tabId) {
      return tab;
    }
  }
  return null;
}

Future<Null> scrapePage(
    browser.Port sourcePort, int windowId, int tabId, String url) async {
  final browser.Tab tab = await determineTab(windowId, tabId);

  _log.fine("Connecting to tab ${tab.id}");
  final browser.Port tabPort = browser.tabs
      .connect(tab.id, name: new Uuid().v4());
  try {
    _log.info("Sending scrape page command to page");
    tabPort.postMessage(
        {messageFieldCommand: scrapePageCommand, messageFieldUrl: url});
    _log.info("Listening for response");
    await for (JsObject message in tabPort.onMessage) {
      _log.info("Message received, forwarding to page");
      _log.fine(jsVarDump(message));
      sourcePort.postMessage(message);
      if (message == endMessageEvent) {
        _log.info("End message event received, disconnecting");
        break;
      }
    }
  } finally {
    tabPort.disconnect();
  }

  _log.finest("scrapePage() end");
}

void subscribeToPage(browser.Port p, int tabId) {
  final StreamSubscription<PageUpdateEvent> pageSub =
      onPageSubscriptionUpdate.listen((PageUpdateEvent e) {
    if (tabId == e.tabId) {
      _log.info(
          "Page update tab id matches subscription, forwarding to listener");
      p.postMessage(e.data);
    }
  });
  if (!pageSubscriptions.containsKey(p.name)) {
    pageSubscriptions[p.name] = <int, StreamSubscription<PageUpdateEvent>>{};
  }
  pageSubscriptions[p.name][tabId] = pageSub;
  // ignore: unawaited_futures
  p.onDisconnect.first.then((e) async {
    await pageSub.cancel();
    pageSubscriptions[p.name].remove(tabId);
  });
}

Future<Null> unsubscribeFromPage(browser.Port p, int tabId) async {
  if (pageSubscriptions.containsKey(p.name) &&
      pageSubscriptions[p.name].containsKey(tabId)) {
    _log.fine("Unsubscribing port ${p.name} from tab $tabId");
    await pageSubscriptions[p.name][tabId].cancel();
    pageSubscriptions[p.name].remove(tabId);
  } else {
    _log.warning("Port ${p.name} does not have a subscription to tab $tabId");
  }
}

Future<Map> _openTab(String url, int windowId) async {
  _log.finest("openTab($url, $windowId) start");
  try {
    final Map output = {messageFieldEvent: tabLoadedMessageEvent};
    browser.Tab tab = await browser.tabs.create(url: url, active: false, windowId: windowId);
    _log.info("Tab created: ${tab.id}");
    _log.info("Waiting for tab to finish loading");
    //await for (chrome.OnUpdatedEvent updatedEvent in chrome.tabs.onUpdated) {
//    _log.finest("Tab updated event received for tab ${updatedEvent.tabId}: ${updatedEvent.changeInfo}");
//    if (updatedEvent.tabId == tab.id &&
//        updatedEvent.changeInfo["status"] == "complete") {
//    _log.info("New tab open complete: ${updatedEvent.tabId}");
    for (int i = 0; i < 5; i++) {
      final e = await browser.runtime.onMessage
          .where((e) =>
              e.message[messageFieldEvent] == pageHealthEvent &&
              e.message[messageFieldTabId] == tab.id)
          .first;

      final JsObject message = e.message;
      _log.finest("Page health event received: ${jsVarDump(message)}");
      switch (message[messageFieldPageHealth]) {
        case pageHealthOk:
          i = 1000;
          break;
        case pageHealthError:
          throw new Exception("Error returned by tab while loading page!");
        case pageHealthResolvableError:
          await browser.tabs
              .reload(tab.id, bypassCache: true);
          continue;
      }
    }
    // Update the tab so we can get the final URL
    tab = await browser.tabs.get(tab.id);
    output[messageFieldTabId] = tab.id;
    output[messageFieldUrl] = tab.url;
    //  }
    //}
    return output;
  } finally {
    _log.finest("openTab($url, $windowId) end");
  }
}

class PageUpdateEvent {
  int tabId;
  dynamic data;

  PageUpdateEvent(this.tabId, this.data);
}

final RegExp pathToTagsRegex = new RegExp("/\d+ - (.+)\.([a-zA-Z0-9]+)/");

String _pathToTags(String file, String path) {
  var tags = [];
  if (pathToTagsRegex.hasMatch(file)) {
    final match = pathToTagsRegex.firstMatch(file);

    tags = match.group(1).split(" ");
  }

  path = path.replaceAll(";", ":");
  path = path = path.replaceAll("__", " ");


  var category = "";
  for(var dir in path.split("/")) {
    var category_to_inherit = "";
    for(var tag in dir.split(" ")) {
      tag = tag.trim();
      if (tag.isEmpty) {
        continue;
      }
      if (tag.endsWith(":")) {
        // This indicates a tag that ends in a colon,
        // which is for inheriting to tags on the subfolder
        category_to_inherit = tag;
      } else {
        if (category.isNotEmpty && !tag.endsWith(":")) {
          // This indicates that category inheritance is active,
          // and we've encountered a tag that does not specify a category.
          // So we attach the inherited category to the tag.
          tag = "{$category}{$tag}";
        }
        tags.add(tag);
      }
    }
    // Category inheritance only works on the immediate subfolder,
    // so we hold a category until the next iteration, and then set
    // it back to an empty string after that iteration
    category = category_to_inherit;
  }

  return tags.join(" ");
}

Future<Null> uploadItem(browser.Port p, message) async {

  final html.FormData formData = new html.FormData();


  formData.append('tags', _pathToTags(message[messageFieldFilename], message[messageFieldPath]));
  formData.append('source', message[messageFieldSource]);


  p.postMessage({
    messageFieldEvent: uploadStartEvent
  });

  final request = await html.HttpRequest.request(message[messageFieldTarget],
      method: 'post',
      sendData: formData);

  if(request.status==302) {
    p.postMessage({
      messageFieldEvent: uploadEndEvent
    });
  } else {
    p.postMessage({
      messageFieldEvent: uploadErrorEvent,
      messageFieldError: request.responseText
    });
  }

}