import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:logging/logging.dart';
import 'package:scraper/sources/sources.dart';

import 'results_component.dart';
import 'services/settings_service.dart';

@Component(
  selector: 'options-page',
  styleUrls: ['options_component.css'],
  templateUrl: 'options_component.html',
  directives: <dynamic>[NgFor, materialDirectives, NgIf, ResultsComponent],
  providers: <dynamic>[
    const ClassProvider(SettingsService),
    sourceProviders,
    const ClassProvider(Sources),
    materialProviders],
)
class OptionsComponent implements OnInit {
  static final Logger _log = new Logger("OptionsComponent");

  final SettingsService _settings;
  final Sources _sources;

  List<String> prefixPaths = <String>[];
  Map<String, String> mappings = <String, String>{};
  Map<String, SourceSettings> sourceSettings = <String, SourceSettings>{};
  String newPrefixPath = "";
  String downloadPathPrefix = "";

  StringSelectionOptions<Level> loggingOptions =
      new StringSelectionOptions<Level>(Level.LEVELS);

  final SelectionModel<Level> singleSelectModel =
      new SelectionModel<Level>.single();

  Level _loggingLevel;

  OptionsComponent(this._settings, this._sources);

  Level get selectionValue => _loggingLevel;

  set selectionValue(Level level) {
    _loggingLevel = level;
  }

  void addPrefixPath() {
    if ((newPrefixPath?.trim() ?? "").isEmpty) {
      return;
    }
    prefixPaths.add(newPrefixPath);
  }

  String levelItemRenderer(Level item) => item.name;

  Future<Null> loadMappings() async {
    this.mappings = await _settings.getMappings();
  }

  Future<Null> loadSourceSettings() async {
    this.sourceSettings = await _settings.getAllSourceSettings();
  }

  Future<Null> loadPaths() async {
    this.prefixPaths = await _settings.getAvailablePrefixes();
  }

  @override
  Future<Null> ngOnInit() async {
    _log.finest("OptionsComponent.ngOnInit start");
    try {
      _loggingLevel = await _settings.getLoggingLevel();
      downloadPathPrefix = await _settings.getDownloadPathPrefix();
    } on Exception catch (e, st) {
      _log.severe("OptionsComponent.ngOnInit error", e, st);
    } finally {
      _log.finest("OptionsComponent.ngOnInit end");
    }
  }

  Future<Null> saveSettings() async {
    await _settings.setLoggingLevel(_loggingLevel);
    await _settings.setDownloadPathPrefix(this.downloadPathPrefix);
  }

  Future<Null> saveMappings() async {
    await _settings.saveMappings(this.mappings, false);
  }

  Future<Null> savePaths() async {
    await _settings.setPrefixPath(this.prefixPaths);
  }

  Future<Null> saveSourceSettings() async {
    await _settings.saveAllSourceSettings(this.sourceSettings);
}

  Future<Null> exportMappings() async {
    final Map<String, String> mappings = await _settings.getMappings();
    final String output = jsonEncode(mappings);

    final Blob blob = new Blob([output], 'text/plain');

    new AnchorElement()
      ..download = 'data.json'
      ..href = Url.createObjectUrlFromBlob(blob)
      ..click();
  }

  Future<Null> importMappings() async {
    final FileUploadInputElement fileUpload = new FileUploadInputElement()
      ..click();

    final Event t = await fileUpload.onChange.first;
    if (fileUpload.files.isEmpty) return;

    final FileReader reader = new FileReader()..readAsText(fileUpload.files[0]);

    await reader.onLoad.first;
    final Map<String, String> data = jsonDecode(reader.result);
    await _settings.saveMappings(data, true);
  }
}
