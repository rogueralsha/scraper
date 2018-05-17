import 'dart:async';
import 'dart:html';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

const String messageFieldEvent = "event";
const String messageFieldUrl = "url";
const String messageFieldTabId = "tabId";
const String messageFieldCommand = "command";
const String messageFieldFilename = "filename";
const String messageFieldHeaders = "headers";
const String messageFieldData = "data";

const String startScrapeCommand = "startScrape";
const String scrapePageCommand = "scrapePage";
const String openTabCommand = "openTab";
const String downloadCommand = "download";
const String getTabIdCommand = "getTabId";
const String closeTabCommand = "closeTab";

const String subscribeCommand = "subscribe";
const String unsubscribeCommand = "unsubscribe";

const String closeTabMessageEvent = "closeTab";
const String tabLoadedMessageEvent = "tabLoaded";
const String endMessageEvent = "endMessage";
const String fileDownloadedEvent = "fileDownloaded";
const String scrapeDoneEvent = "scrapeDone";

const String pageInfoEvent = "pageInfo";
const String linkInfoEvent = "linkInfo";

final RegExp siteRegexp =
    new RegExp("https?://([^/]+)/.*", caseSensitive: false);

final Logger _log = new Logger("globals");

void closeTab({int tabId}) {
  _log.info("Sending close tab message");
  final Map<String, dynamic> message = <String, dynamic>{
    messageFieldCommand: closeTabMessageEvent
  };
  if (tabId != null) {
    message[messageFieldTabId] = tabId;
  }
  _log.info(message);
  chrome.runtime.sendMessage(message);
}

Future<int> getCurrentTabId() async {
  _log.info("Getting current tab id");
  final chrome.Port p = chrome.runtime
      .connect(null, new chrome.RuntimeConnectParams(name: new Uuid().v4()));
  try {
    p.postMessage({messageFieldCommand: getTabIdCommand});
    final chrome.OnMessageEvent e = await p.onMessage.first;
    _log.info("Current tab ID is: ${e.message[messageFieldTabId]}");
    return e.message[messageFieldTabId];
  } finally {
    p.disconnect();
  }
}

bool inIframe() {
  try {
    return window.self != window.top;
  } catch (e) {
    return true;
  }
}
