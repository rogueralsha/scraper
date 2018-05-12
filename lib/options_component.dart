import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'src/todo_list/todo_list_component.dart';
import 'package:logging/logging.dart';
import 'services/settings_service.dart';
import 'results_component.dart';

@Component(
  selector: 'options-page',
  styleUrls: ['options_component.css'],
  templateUrl: 'options_component.html',
  directives: [TodoListComponent, NgFor, materialDirectives, NgIf, ResultsComponent],
  providers: [const ClassProvider(SettingsService), materialProviders],
)
class OptionsComponent implements OnInit {
  final _log = new Logger("ResultsDialog");

  final SettingsService _settings;

  List<String> prefixPaths = <String>[];
  Map<String,String> mappings = <String,String>{};
  String newPrefixPath = "";

  OptionsComponent(this._settings);

  void addPrefixPath() {
    if((newPrefixPath?.trim()??"").isEmpty) {
      return;
    }
    prefixPaths.add(newPrefixPath);
  }

  Future<Null> ngOnInit() async {
    _log.finest("OptionsComponent.ngOnInit start");
    try {
    } catch(e,st) {
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
