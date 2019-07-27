import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'package:stack_trace/stack_trace.dart';
import 'web_extensions/web_extensions.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

const String closeTabCommand = "closeTab";
const String closeTabMessageEvent = "closeTab";
const String downloadCommand = "download";
const String uploadCommand = "upload";
const String endMessageEvent = "endMessage";
const String fileDownloadCompleteEvent = "fileDownloadComplete";
const String fileDownloadErrorEvent = "fileDownloadError";
const String fileDownloadStartEvent = "fileDownloadStarted";

const String uploadStartEvent = "uploadStart";
const String uploadEndEvent = "uploadEnd";
const String uploadErrorEvent = "uploadError";

const String getTabIdCommand = "getTabId";
const String linkInfoEvent = "linkInfo";
const String pageHealthEvent = "pageHealth";

const String loadWholePageCommand = "loadWholePage";
const String messageFieldCommand = "command";
const String messageFieldData = "data";
const String messageFieldDownloadId = "downloadId";
const String messageFieldError = "error";
const String messageFieldEvent = "event";
const String messageFieldFilename = "filename";
const String messageFieldReferrer = "source";
const String messageFieldSource = "source";
const String messageFieldPrompt = "prompt";
const String messageFieldPath = "path";
const String messageFieldPageHealth = "pageHealth";
const String messageFieldTarget = "target";

const String messageFieldHeaders = "headers";
const String messageFieldTabId = "tabId";

const String messageFieldUrl = "url";
const String openTabCommand = "openTab";
const String nextTabCommand = "nextTab";
const String pageInfoEvent = "pageInfo";
const String scrapeDoneEvent = "scrapeDone";
const String scrapePageCommand = "scrapePage";
const String startScrapeCommand = "startScrape";
const String subscribeCommand = "subscribe";

const String tabLoadedMessageEvent = "tabLoaded";
const String unsubscribeCommand = "unsubscribe";

const String pageHealthOk = "OK";
const String pageHealthError = "Error";
const String pageHealthResolvableError = "ResolvableError";

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
  browser.runtime.sendMessage(message);
}

Future<int> getCurrentTabId() async {
  _log.info("Getting current tab id");
  final Port p = browser.runtime
      .connect(name: new Uuid().v4());
  try {
    p.postMessage({messageFieldCommand: getTabIdCommand});
    final JsObject message = await p.onMessage.first;
    _log.info("Current tab ID is: ${message[messageFieldTabId]}");
    return message[messageFieldTabId];
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

String jsVarDump(JsObject input) => input==null ? "NULL" :
    context['JSON'].callMethod('stringify', <dynamic>[input]);

String getFileNameFromUrl(String link) => Uri
    .decodeComponent(link.substring(link.lastIndexOf('/') + 1).split("?")[0]);

void logToConsole(LogRecord rec) {
  print('${rec.level.name}: ${rec.time}: ${rec.message}');
  if (rec.error != null) {
    print(rec.error.toString());
  }
  if (rec.stackTrace != null) {
    print(Trace.format(rec.stackTrace));
  }
}