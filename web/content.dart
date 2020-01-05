import 'dart:async';
import 'dart:html';
import 'package:angular/angular.dart';
import 'package:scraper/scraper_component.template.dart' as ng;
import 'package:logging/logging.dart';
import 'package:scraper/globals.dart';
import 'package:scraper/web_extensions/web_extensions.dart' as browser;
import 'dart:html';
import 'dart:js';

final Logger _log = new Logger("content.dart");
Future<Null> main() async {
  int tabId = await getCurrentTabId();
  // Page health check
  if (document.body.text.contains("429 Too Many Requests") ||
      document.body.text
          .contains("If you’re not redirected soon, please use this link.")) {
    await pause(seconds: 5);
    await browser.runtime.sendMessage({
      messageFieldEvent: pageHealthEvent,
      messageFieldTabId: tabId,
      messageFieldPageHealth: pageHealthResolvableError
    });
    return;
  }

  final Element ele = document.createElement("scraper-component");
  document.body.append(ele);
  runApp(ng.ScraperComponentNgFactory);

  await browser.runtime.sendMessage({
    messageFieldEvent: pageHealthEvent,
    messageFieldTabId: tabId,
    messageFieldPageHealth: pageHealthOk
  });
}
