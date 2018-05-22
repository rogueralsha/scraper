import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:logging/logging.dart';

import 'results_component.dart';
import 'services/settings_service.dart';

@Component(
  selector: 'options-page',
  styleUrls: ['options_component.css'],
  templateUrl: 'options_component.html',
  directives: <dynamic>[NgFor, materialDirectives, NgIf, ResultsComponent],
  providers: <dynamic>[const ClassProvider(SettingsService), materialProviders],
)
class OptionsComponent implements OnInit {
  static final Logger _log = new Logger("ResultsDialog");

  final SettingsService _settings;

  List<String> prefixPaths = <String>[];
  Map<String, String> mappings = <String, String>{};
  String newPrefixPath = "";

  StringSelectionOptions<Level> loggingOptions =
      new StringSelectionOptions<Level>(Level.LEVELS);

  final SelectionModel<Level> singleSelectModel = new SelectionModel<Level>.single();

  Level _loggingLevel;

  OptionsComponent(this._settings);

  Level get selectionValue => _loggingLevel;

  set selectionValue(Level level) {
    _loggingLevel = level;
    _settings.setLoggingLevel(level);
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

  Future<Null> loadPaths() async {
    this.prefixPaths = await _settings.getAvailablePrefixes();
  }

  @override
  Future<Null> ngOnInit() async {
    _log.finest("OptionsComponent.ngOnInit start");
    try {
      _loggingLevel = await _settings.getLoggingLevel();
    } on Exception catch (e, st) {
      _log.severe("OptionsComponent.ngOnInit error", e, st);
    } finally {
      _log.finest("OptionsComponent.ngOnInit end");
    }
  }

  Future<Null> saveMappings() async {
    await _settings.saveMappings(this.mappings);
  }

  Future<Null> savePaths() async {
    await _settings.setPrefixPath(this.prefixPaths);
  }
}
