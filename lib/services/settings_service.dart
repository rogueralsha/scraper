import 'dart:async';
import 'dart:html';
import 'package:angular/angular.dart';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:logging/logging.dart';
import 'package:scraper/data/source_artist_setting.dart';
import 'package:scraper/sources/sources.dart';

export 'package:scraper/data/source_artist_setting.dart';

@Injectable()
class SettingsService {
  static final Logger _log = new Logger("SettingsService");

  static const String _mappingStore = "mappingStore";
  static const String _settingsStore = "settingsStore";
  static const String _sourceSettingsStore = "sourceSettingsStore";

  static const String _sourceArtistSettingStore = "sourceArtistSettingsStore";

  //static const String _artistField = "artist";

  static const String _pathField = "path";
  static const String _suffixField = "suffix";
  static const String _maxConcurrentDownloadsField = "maxConcurrentDownloads";

  static const String _availablePrefixesSetting = "availablePrefixes";

  static const String _downloadPathPrefixSetting = "downloadPathPrefix";

  static const String _loggingLevelSetting = "";

  SettingsService();

  String cleanPath(String input) => input.replaceAll("\\", "/");

  Future<List<String>> getAvailablePrefixes() async {
    final Map results = await chrome.storage.local
        .get("${_settingsStore}_$_availablePrefixesSetting");
    if (results.isEmpty) return [];

    return results[results.keys.first];
  }

  Future<String> getDownloadPathPrefix() async {
    final Map results = await chrome.storage.local
        .get("${_settingsStore}_$_downloadPathPrefixSetting");
    if (results.isEmpty) return "";

    return results[results.keys.first];
  }

  Future<Level> getLoggingLevel() async {
    final Map<dynamic, dynamic> results = await chrome.storage.local
        .get("${_settingsStore}_$_loggingLevelSetting");

    if (results?.isNotEmpty ?? false) {
      final int value = results[results.keys.first];

      for (Level lvl in Level.LEVELS) {
        if (lvl.value == value) {
          return lvl;
        }
      }
    }

    return Level.INFO;
  }

  Future<String> getMapping(String name) async {
    if (name?.trim()?.isEmpty ?? false) throw new ArgumentError.notNull("name");
    name = name?.trim()?.toLowerCase();
    final Map results = await chrome.storage.local.get(_artistPath(name));
    if (results.isEmpty) return "";

    return results[results.keys.first][_pathField];
  }

  Future<Map<String, String>> getMappings() async {
    final Map<String, String> output = <String, String>{};

    final Map pairs = await chrome.storage.local.get();
    for (String key in pairs.keys) {
      if (key.startsWith(_mappingStore)) {
        output[key.substring(_mappingStore.length + 1)] =
            pairs[key][_pathField];
      }
    }
    _log..info("Found ${output.length} mappings")..info(output);
    return output;
  }

  Future<Map<String, SourceSettings>> getAllSourceSettings() async {
    final Map<String, SourceSettings> output = <String, SourceSettings>{};

    // Sources.sourceInstances is only populated if Sources has been instantiated
    // This will happen in the options page and nowhere else
    for(ASource source in Sources.sourceInstances) {
      output[source.sourceName] = await getSourceSettings(source.sourceName);
    }
    _log..info("Found ${output.length} sourceSettings")..info(output);
    return output;
  }

  Future<SourceSettings> getSourceSettings(String name) async {
    final Map results = await chrome.storage.local.get(_sourceSettingsPath(name));

    final SourceSettings output = new SourceSettings();
    if (results.isEmpty) return output;

    _log..info("Found ${results.length} source setting keys")
      ..info(results[results.keys.first]);
      output.suffix = results[results.keys.first][_suffixField];
    _log.info(output);
    return output;
  }

  Future<int> getMaxConcurrentDownloads() async {
    final Map<dynamic, dynamic> results = await chrome.storage.local
        .get("${_settingsStore}_$_maxConcurrentDownloadsField");

    if (results?.isNotEmpty ?? false) {
      final int value = results[results.keys.first];
      return value ?? 1;
    }

    return 1;
  }

  Future<Null> removeMapping(String name) async {
    if (name?.trim()?.isEmpty ?? false) throw new ArgumentError.notNull("name");
    await chrome.storage.local.remove(_artistPath(name));
    _log.info("Removed mapping for $name");
  }

  Future<Null> saveMappings(Map<String, String> mappings, bool merge) async {
    if (!merge) {
      final Map pairs = await chrome.storage.local.get();
      for (String key in pairs.keys) {
        if (key.startsWith(_mappingStore)) {
          await chrome.storage.local.remove(key);
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
    await chrome.storage.local.set(<String, dynamic>{
      "${_settingsStore}_$_loggingLevelSetting": level.value
    });
  }

  Future<Null> setDownloadPathPrefix(String path) async {
    _log.info("Setting download prefix to $path");
    await chrome.storage.local.set(<String, dynamic>{
      "${_settingsStore}_$_downloadPathPrefixSetting": path
    });
  }

  Future<Null> setMapping(String name, String path) async {
    if (name?.trim()?.isEmpty ?? false) throw new ArgumentError.notNull("name");
    final String cleaName = name?.toLowerCase();
    final String cleanPath = this.cleanPath(path);
    final Map<String, dynamic> artistData = <String, dynamic>{
      _pathField: cleanPath
    };
    await chrome.storage.local
        .set(<String, dynamic>{_artistPath(cleaName): artistData});
    _log.info("Mapping saved for $cleaName: $cleanPath");
  }

  Future<Null> saveAllSourceSettings(Map<String,SourceSettings> settings) async {
    _log.finest("saveAllSourceSettings($settings)");
    for(String k in settings.keys) {
      await saveSourceSettings(k, settings[k]);
    }
  }

  Future<Null> saveSourceSettings(String name, SourceSettings settings) async {
    _log.finest("saveSourceSettings($name, $settings)");

    final Map<String, dynamic> data = <String, dynamic>{
      _suffixField: settings.suffix
    };
    await chrome.storage.local
        .set(<String, dynamic>{_sourceSettingsPath(name): data});
  }

  Future<Null> setSourceArtistSettings(
      String source, String artist, SourceArtistSetting settings) async {
    _log.finest("setSourceArtistSettings($source, $artist, $settings)");
    await chrome.storage.local.set(<String, dynamic>{
      "${_sourceArtistSettingStore}_${source}_$artist": settings.toJson()
    });
  }

  Future<SourceArtistSetting> getSourceArtistSettings(
      String source, String artist) async {
    _log.finest("getSourceArtistSettings($source, $artist)");
    final String key = "${_sourceArtistSettingStore}_${source}_$artist";
    final Map<dynamic, dynamic> results = await chrome.storage.local.get(key);

    _log.finer(results);
    if (results?.isNotEmpty ?? false) {
      return new SourceArtistSetting.fromMap(results[key]);
    }

    return new SourceArtistSetting();
  }

  Future<Null> setMaxConcurrentDownloads(int value) async {
    _log.info("Setting max concurrent downloads to ${value}");
    await chrome.storage.local.set(<String, dynamic>{
      "${_settingsStore}_$_maxConcurrentDownloadsField": value
    });
  }

  Future<Null> setPrefixPath(List<String> paths) async {
    for (int i = 0; i < paths.length; i++) {
      paths[i] = cleanPath(paths[i]);
    }

    await chrome.storage.local.set(<String, dynamic>{
      "${_settingsStore}_$_availablePrefixesSetting": paths
    });
  }

  String _artistPath(String name) => "${_mappingStore}_$name";
  String _sourceSettingsPath(String name) => "${_sourceSettingsStore}_$name";
}

class SourceSettings {
  String suffix;

  @override
  String toString() {
    return "suffix: $suffix";
  }
}