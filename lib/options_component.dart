import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:logging/logging.dart';
import 'services/settings_service.dart';
import 'results_component.dart';

@Component(
  selector: 'options-page',
  styleUrls: ['options_component.css'],
  templateUrl: 'options_component.html',
  directives: [NgFor, materialDirectives, NgIf, ResultsComponent],
  providers: [const ClassProvider(SettingsService), materialProviders],
)
class OptionsComponent implements OnInit {
  static final Logger _log = new Logger("ResultsDialog");

  final SettingsService _settings;

  List<String> prefixPaths = <String>[];
  Map<String, String> mappings = <String, String>{};
  String newPrefixPath = "";

  StringSelectionOptions<Level> loggingOptions =
      new StringSelectionOptions<Level>(Level.LEVELS);

  final SelectionModel<Level> singleSelectModel = new SelectionModel.single();

  static ItemRenderer<Level> levelItemRenderer = (Level item) => item.name;

  OptionsComponent(this._settings);

  void addPrefixPath() {
    if ((newPrefixPath?.trim() ?? "").isEmpty) {
      return;
    }
    prefixPaths.add(newPrefixPath);
  }

  Level _loggingLevel;
  Level get selectionValue => _loggingLevel;
  set selectionValue(Level level) {
    _loggingLevel = level;
    _settings.setLoggingLevel(level);
  }

  Future<Null> ngOnInit() async {
    _log.finest("OptionsComponent.ngOnInit start");
    try {
      _loggingLevel = await _settings.getLoggingLevel();
    } catch (e, st) {
      _log.severe("OptionsComponent.ngOnInit error", e, st);
    } finally {
      _log.finest("OptionsComponent.ngOnInit end");
    }
  }

  Future<Null> savePaths() async {
    await _settings.setPrefixPath(this.prefixPaths);
  }

  Future<Null> loadPaths() async {
    this.prefixPaths = await _settings.getAvailablePrefixes();
  }

  Future<Null> loadMappings() async {
    this.mappings = await _settings.getMappings();
  }

  Future<Null> saveMappings() async {
    await _settings.saveMappings(this.mappings);
  }
}
