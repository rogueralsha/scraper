import 'dart:async';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:scraper/web_extensions/web_extensions.dart';
import 'package:scraper/data/source_artist_setting.dart';

export 'package:scraper/data/source_artist_setting.dart';

@Injectable()
class SettingsService {
  static final Logger _log = new Logger("SettingsService");

  static const String _mappingStore = "mappingStore";
  static const String _settingsStore = "settingsStore";

  static const String _sourceArtistSettingStore = "sourceArtistSettingsStore";

  //static const String _artistField = "artist";
  static const String _pathField = "path";
  static const String _maxConcurrentDownloadsField = "maxConcurrentDownloads";

  static const String _availablePrefixesSetting = "availablePrefixes";

  static const String _downloadPathPrefixSetting = "downloadPathPrefix";
  static const String _shimmiePathSetting = "shimmiePath";

  static const String _loggingLevelSetting = "";

  SettingsService();

  String cleanPath(String input) => input.replaceAll("\\", "/");

  Future<List<String>> getAvailablePrefixes() async {
    final Map results = await browser.storage.local
        .get(keys:["${_settingsStore}_$_availablePrefixesSetting"]);
    if (results.isEmpty) return [];

    return results[results.keys.first];
  }

  Future<String> getDownloadPathPrefix() async {
    final Map results = await browser.storage.local
        .get(keys:["${_settingsStore}_$_downloadPathPrefixSetting"]);
    if (results.isEmpty) return "";

    return results[results.keys.first];
  }

  Future<String> getShimmiePath() async {
    final Map results = await browser.storage.local
        .get(keys:["${_settingsStore}_$_shimmiePathSetting"]);
    if (results.isEmpty) return "";

    return results[results.keys.first];
  }

  Future<Level> getLoggingLevel() async {
    final Map<dynamic, dynamic> results = await browser.storage.local
        .get(keys:["${_settingsStore}_$_loggingLevelSetting"]);

    if (results?.isNotEmpty ?? false) {
      final int value = results[results.keys.first];

      for (Level lvl in Level.LEVELS) {
        if (lvl.value == value) {
          return lvl;
        }
      }
    }

    return Level.ALL;
  }

  Future<String> getMapping(String name) async {
    if (name?.trim()?.isEmpty ?? false) throw new ArgumentError.notNull("name");
    name = name.trim().toLowerCase();
    final Map results = await browser.storage.local.get(keys:[_artistPath(name)]);
    if (results.isEmpty||results[results.keys.first]==null) return "";

    return results[results.keys.first][_pathField];
  }

  Future<Map<String, String>> getMappings() async {
    final Map<String, String> output = <String, String>{};

    final Map pairs = await browser.storage.local.get();
    for (String key in pairs.keys) {
      if (key.startsWith(_mappingStore)) {
        output[key.substring(_mappingStore.length + 1)] =
            pairs[key][_pathField];
      }
    }
    _log..info("Found ${output.length} mappings")..info(output);
    return output;
  }

  Future<int> getMaxConcurrentDownloads() async {
    final Map<dynamic, dynamic> results = await browser.storage.local
        .get(keys:["${_settingsStore}_$_maxConcurrentDownloadsField"]);

    if (results?.isNotEmpty ?? false) {
      final int value = results[results.keys.first];
      return value ?? 1;
    }

    return 1;
  }

  Future<Null> removeMapping(String name) async {
    if (name?.trim()?.isEmpty ?? false) throw new ArgumentError.notNull("name");
    await browser.storage.local.remove(_artistPath(name));
    _log.info("Removed mapping for $name");
  }

  Future<Null> saveMappings(Map<String, String> mappings, bool merge) async {
    if (!merge) {
      final Map pairs = await browser.storage.local.get();
      for (String key in pairs.keys) {
        if (key.startsWith(_mappingStore)) {
          await browser.storage.local.remove(key);
        }
      }
    }

    for (String artist in mappings.keys) {
      if (artist?.isEmpty ?? true) continue;
      await setMapping(artist, mappings[artist]);
    }
    _log.info("Saved new paths for artists");
  }

  Future<Null> setLoggingLevel(Level level) async {
    _log.info("Setting logging level to ${level.name}");
    await browser.storage.local.set(<String, dynamic>{
      "${_settingsStore}_$_loggingLevelSetting": level.value
    });
  }

  Future<Null> setDownloadPathPrefix(String path) async {
    _log.info("Setting download prefix to $path");
    await browser.storage.local.set(<String, dynamic>{
      "${_settingsStore}_$_downloadPathPrefixSetting": path
    });
  }

  Future<Null> setShimmiePath(String path) async {
    _log.info("Setting shimmie path to $path");
    await browser.storage.local.set(<String, dynamic>{
      "${_settingsStore}_$_shimmiePathSetting": path
    });
  }

  Future<Null> setMapping(String name, String path) async {
    if (name?.trim()?.isEmpty ?? false) throw new ArgumentError.notNull("name");
    final String cleaName = name.toLowerCase();
    final String cleanPath = this.cleanPath(path);
    final Map<String, dynamic> artistData = <String, dynamic>{
      _pathField: cleanPath
    };
    await browser.storage.local
        .set(<String, dynamic>{_artistPath(cleaName): artistData});
    _log.info("Mapping saved for $cleaName: $cleanPath");
  }

  Future<Null> setSourceArtistSettings(
      String source, String artist, SourceArtistSetting settings) async {
    _log.finest("setSourceArtistSettings($source, $artist, $settings)");
    await browser.storage.local.set(<String, dynamic>{
      "${_sourceArtistSettingStore}_${source}_$artist": settings.toJson()
    });
  }

  Future<SourceArtistSetting> getSourceArtistSettings(
      String source, String artist) async {
    _log.finest("getSourceArtistSettings($source, $artist)");
    final String key = "${_sourceArtistSettingStore}_${source}_$artist";
    final Map<dynamic, dynamic> results = await browser.storage.local.get(keys:[key]);


    _log.finer(results);
    if (results?.isNotEmpty ?? false) {
      return new SourceArtistSetting.fromMap(results[key]);
    }

    return new SourceArtistSetting();
  }

  Future<Null> setMaxConcurrentDownloads(int value) async {
    _log.info("Setting max concurrent downloads to ${value}");
    await browser.storage.local.set(<String, dynamic>{
      "${_settingsStore}_$_maxConcurrentDownloadsField": value
    });
  }

  Future<Null> setPrefixPath(List<String> paths) async {
    for (int i = 0; i < paths.length; i++) {
      paths[i] = cleanPath(paths[i]);
    }

    await browser.storage.local.set(<String, dynamic>{
      "${_settingsStore}_$_availablePrefixesSetting": paths
    });
  }

  String _artistPath(String name) => "${_mappingStore}_$name";
}
