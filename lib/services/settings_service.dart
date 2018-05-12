import 'dart:async';
import 'package:logging/logging.dart';
import 'package:chrome/chrome_ext.dart' as chrome;


class SettingsService {
  static final Logger _log = new Logger("SettingsService");

  static const String _mappingStore = "mappingStore";
  static const String _settingsStore = "settingsStore";

  //static const String _artistField = "artist";
  static const String _pathField = "path";

  static const String _availablePrefixesSetting = "availablePrefixes";

  SettingsService() {

  }

  String _artistPath(String name) => "${_mappingStore}_$name";

  Future<Null> setMapping(String name, String path) async {
    if(name?.trim()?.isEmpty??false)
      throw new ArgumentError.notNull("name");
    name = name.toLowerCase();
    path = cleanPath(path);
    Map artistData = {_pathField: path };
    await chrome.storage.local.set({_artistPath(name): artistData});
    _log.info("Mapping saved for " + name + ": " + path);

  }

  Future<Null> removeMapping(String name) async {
    if(name?.trim()?.isEmpty??false)
      throw new ArgumentError.notNull("name");
    await chrome.storage.local.remove(_artistPath(name));
    _log.info("Removed mapping for " + name);
  }


  Future<List<String>> getAvailablePrefixes() async {
    Map results = await chrome.storage.local.get("${_settingsStore}_$_availablePrefixesSetting");
    if(results.isEmpty)
      return [];

    return results[results.keys.first];
  }

  String cleanPath(String input) => input.replaceAll("\\","/");

  Future<Null> setPrefixPath(List<String> paths) async {
    for(int i = 0; i< paths.length; i++) {
      paths[i] = cleanPath(paths[i]);
    }


    await chrome.storage.local.set(
        {"${_settingsStore}_$_availablePrefixesSetting": paths});
  }


  Future<Map<String,String>> getMappings() async {
    Map<String, String> output = <String,String>{};

    Map pairs = await chrome.storage.local.get();
    for(String key in pairs.keys) {
      if(key.startsWith(_mappingStore)) {
        output[key.substring(_mappingStore.length+1)] = pairs[key][_pathField];
      }
    }
    _log.info("Found ${output.length} mappings");
    _log.info(output);
    return output;
  }


  Future<Null> saveMappings(Map<String,String> mappings) async {
    Map pairs = await chrome.storage.local.get();
    for(String key in pairs.keys) {
      if(key.startsWith(_mappingStore)) {
        await chrome.storage.local.remove(key);
      }
    }

    for(String artist in mappings.keys) {
      await setMapping(artist, mappings[artist]);
    }
    _log.info("Saved new paths for artists");
  }



  Future<String> getMapping(String name) async {
    if(name?.trim()?.isEmpty??false)
      throw new ArgumentError.notNull("name");
    name = name.trim().toLowerCase();
    Map results = await chrome.storage.local.get(_artistPath(name));
    if(results.isEmpty)
      return "";

    return results[results.keys.first][_pathField];
  }


}