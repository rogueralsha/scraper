import 'dart:html';
import 'dart:js';
import 'dart:async';
import 'package:logging/logging.dart';
import '../results/page_info.dart';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:scraper/globals.dart';
import 'package:uuid/uuid.dart';

class PageStreamEvent {}

class PageStreamService {
  static final _log = new Logger("ScraperService");

  Stream<PageInfo> get onPageInfo => _pageInfoStream.stream;
  StreamController<PageInfo> _pageInfoStream = new StreamController<PageInfo>();

  Stream<LinkInfo> get onLinkInfo => _linkInfoStream.stream;
  StreamController<LinkInfo> _linkInfoStream = new StreamController<LinkInfo>();

  final chrome.Port p;

  PageStreamService()
      : p = chrome.runtime.connect(
            null, new chrome.RuntimeConnectParams(name: new Uuid().v4())) {
    p.onMessage.listen(messageEvented);
    setUpStreams();
  }

  Future<Null> setUpStreams() async {
    _log.finest("setUpStreams start");
    try {
      p.postMessage({
        messageFieldCommand: subscribeCommand,
        messageFieldTabId: await getCurrentTabId()
      });
    } finally {
      _log.finest("setUpStreams end");
    }
  }

  Future<Null> requestScrapeStart({String url}) async {
    p.postMessage({
      messageFieldCommand: startScrapeCommand,
      messageFieldTabId: await getCurrentTabId(),
      messageFieldUrl: url ?? window.location.href
    });
  }

  Future<Null> requestLoadWholePage({String url}) async {
    p.postMessage({
      messageFieldCommand: loadWholePageCommand,
      messageFieldTabId: await getCurrentTabId(),
      messageFieldUrl: url ?? window.location.href
    });
  }

  void messageEvented(chrome.OnMessageEvent e) {
    try {
      final JsObject obj = e.message;
      if (obj.hasProperty(messageFieldEvent)) {
        final String event = obj[messageFieldEvent];
        switch (event) {
          case pageInfoEvent:
            final PageInfo pi =
                new PageInfo.fromJsObject(obj[messageFieldData]);
            _pageInfoStream.add(pi);
            break;
          case linkInfoEvent:
            final LinkInfo li = new LinkInfo.fromJson(obj[messageFieldData]);
            _linkInfoStream.add(li);
            break;
          case scrapeDoneEvent:
            // Doesn't do anything here
            break;
          default:
            throw new Exception("Unknown event: $event");
        }
      } else {
        throw new Exception("Unsupported message received");
      }
    } catch (e, st) {
      _log.info("messageEvented", e, st);
    }
  }
}
