import 'package:chrome/chrome_ext.dart' as chrome;

const String messageFieldEvent = "event";
const String messageFieldUrl = "url";
const String messageFieldTabId = "tabId";
const String messageFieldCommand = "command";
const String messageFieldFilename = "filename";
const String messageFieldHeaders = "headers";
const String messageFieldData = "data";

const String scrapePageCommand = "scrapePage";
const String openTabCommand = "openTab";
const String downloadCommand = "download";
const String getTabIdCommand = "getTabId";
const String closeTabCommand = "closeTab";

const String closeTabMessageEvent = "closeTab";
const String tabLoadedMessageEvent = "tabLoaded";
const String endMessageEvent = "endMessage";
const String fileDownloadedEvent = "fileDownloaded";
const String scrapeDoneEvent = "scrapeDone";

void closeTab({int tabId}) {
  Map message = {messageFieldCommand: closeTabMessageEvent};
  if(tabId!=null) {
    message[messageFieldTabId] = tabId;
  }
  chrome.runtime.sendMessage(message);
}