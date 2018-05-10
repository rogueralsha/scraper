import 'package:scraper/globals.dart';
import 'dart:async';
import 'dart:html';
import 'a_source.dart';
import 'package:logging/logging.dart';
import 'package:chrome/chrome_ext.dart' as chrome;

class DeviantArtSource extends ASource {
  final _log = new Logger("DeviantArtSource");

  static final RegExp _galleryRegExp = new RegExp(
      "https?://([^\\.]+)\\.deviantart\\.com/gallery/.*",
      caseSensitive: false);
  static final RegExp _artRegExp = new RegExp(
      "https?://([^\\.]+)\\.deviantart\\.com/art/.*",
      caseSensitive: false);
  static final RegExp _sandboxRegExp =
      new RegExp("https?://sandbox\\.deviantart\\.com.*", caseSensitive: false);
  static const String _galleryItemSelector = "a.torpedo-thumb-link";

  final Map<String,String> _cachedLinks = <String,String>{};

  void _addLinkToCache(link, thumbnail) {
    if (!_cachedLinks.containsKey(link)) {
      _log.info("Found URL: " + link);
      this._cachedLinks[link] = thumbnail;
    }
  }

  void _scrapeNode(Node node) {
    ElementList eles = document.querySelectorAll(_galleryItemSelector);
    for (int i = 0; i < eles.length; i++) {
      Element ele = eles[i];
      ImageElement imgEle = ele.querySelector("img");
      if (ele is AnchorElement) {
        this._addLinkToCache(ele.href, imgEle.src);
      }
    }
  }

  @override
  bool attachPageListener(String url, Document document) {
    if (!_galleryRegExp.hasMatch(url)) return false;
    _log.info("Deviantart gallery detected, attaching live link gathering");

    _scrapeNode(document);

    MutationObserver observer = new MutationObserver((mutations, mutation) {
      mutations.forEach((mutation) {
        if (mutation.type != "childList" || mutation.addedNodes.length == 0) {
          return;
        }
        for (int j = 0; j < mutation.addedNodes.length; j++) {
          Node node = mutation.addedNodes[j];
          _scrapeNode(node);
        }
      });
    });

    observer.observe(document, childList: true, subtree: true);
    return true;
  }

  Future<ScrapeResults> scrapePage(String url, Document document) async {
    final ScrapeResults output = new ScrapeResults(await ASource.getCurrentTabId());

    if (_artRegExp.hasMatch(url)) {
      output.matchFound = true;

      _log.info("Deviantart page detected");
      Match matches = _artRegExp.firstMatch(url);
      output.artist = matches[1];
      _log.info("Artist: " + output.artist);

      AnchorElement downloadEle = document.querySelector(".dev-page-download");
      String download_url;
      if (downloadEle == null) {
        // This means the download button wasn't found
        ImageElement imgEle = document.querySelector(".dev-content-full");
        if (imgEle == null) {
          IFrameElement iFrameEle = document.querySelector("iframe.flashtime");
          if (iFrameEle == null) {
            output.error = "No media found";
          } else {
            // Embedded flash file without a download button
            int tabId = await ASource.getCurrentTabId();
            ScrapeResults response = await _getPageContentsFromIframe(tabId, iFrameEle.src);
            if (response != null) {
              for (int i = 0, len = response.results.length; i < len; i++) {
                output.addResult(response.results[i]);
              }
            }
          }
        } else {
          _log.info("Found URL: " + imgEle.src);
          output
              .addResult(new ScrapeResultImpl(imgEle.src, type: ResultTypes.image));
        }
      } else {
        _log.info("Found URL: " + downloadEle.href);
        output.addResult(
            new ScrapeResultImpl(downloadEle.href, type: ResultTypes.image));
      }
    } else if (_galleryRegExp.hasMatch(url)) {
      output.matchFound = true;
      _log.info("Deviantart gallery detected");
      Match m = _galleryRegExp.firstMatch(url);
      output.artist = m.group(1);
      _log.info("Artist: " + output.artist);

      _scrapeNode(document);

      if (_cachedLinks?.length ?? 0 == 0) {
        output.error = "No media found";
      }
      for(String link in _cachedLinks.keys) {
        _log.info("Found URL: " + link);
        output.addResult(new ScrapeResultImpl(link, type: ResultTypes.page, thumbnail: _cachedLinks[link]));
      }
    } else if (_sandboxRegExp.hasMatch(url)) {
      _log.info("Deviantart sandbox");
      output.matchFound = true;
      EmbedElement ele = document.querySelector("embed#sandboxembed");
      if (ele != null) {
        String link = ele.src;
        output.addResult(new ScrapeResultImpl(link));
      }
    }

    return output;
  }

  Future<ScrapeResults> _getPageContentsFromIframe(int tabId, String iframeUrl) async {

    ScrapeResults results = await  chrome.runtime
        .sendMessage({messageFieldCommand: scrapePageCommand,
      messageFieldTabId: tabId,
      messageFieldUrl: iframeUrl});

    if (results == null) {
      _log.warning("No media found in iframe (null)");
      return null;
    }

    if (results.error != null) {
      _log.severe(results.error);
    } else if (results.results.length == 0) {
      _log.info("No media found in iframe");
    } else {
      return results;
    }
    return null;
  }
}
