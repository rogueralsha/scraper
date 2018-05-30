import 'dart:async';
import 'dart:html';

import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

const String closeTabCommand = "closeTab";
const String closeTabMessageEvent = "closeTab";
const String downloadCommand = "download";
const String endMessageEvent = "endMessage";
const String fileDownloadCompleteEvent = "fileDownloadComplete";
const String fileDownloadErrorEvent = "fileDownloadError";
const String fileDownloadStartEvent = "fileDownloadStarted";
const String getTabIdCommand = "getTabId";
const String linkInfoEvent = "linkInfo";

const String loadWholePageCommand = "loadWholePage";
const String messageFieldCommand = "command";
const String messageFieldData = "data";
const String messageFieldDownloadId = "downloadId";
const String messageFieldError = "error";
const String messageFieldEvent = "event";
const String messageFieldFilename = "filename";

const String messageFieldHeaders = "headers";
const String messageFieldTabId = "tabId";

const String messageFieldUrl = "url";
const String openTabCommand = "openTab";
const String pageInfoEvent = "pageInfo";
const String scrapeDoneEvent = "scrapeDone";
const String scrapePageCommand = "scrapePage";
const String startScrapeCommand = "startScrape";
const String subscribeCommand = "subscribe";

const String tabLoadedMessageEvent = "tabLoaded";
const String unsubscribeCommand = "unsubscribe";

final RegExp siteRegexp =
    new RegExp(r"https?://([^/]+)/.*", caseSensitive: false);

final RegExp notCapitalRegexp = new RegExp(r"[^A-Z]");

const String capitalLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

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
  } on Exception catch (e) {
    return true;
  }
}

Future<Null> pause({int seconds = 0}) =>
    new Future<Null>.delayed(new Duration(seconds: seconds));
