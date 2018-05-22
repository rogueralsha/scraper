import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:logging/logging.dart';
import 'services/scraper_service.dart';
import 'results_component.dart';
import 'globals.dart';

// AngularDart info: https://webdev.dartlang.org/angular
// Components info: https://webdev.dartlang.org/components

@Component(
  selector: 'results-dialog',
  styleUrls: ['results_dialog.css'],
  templateUrl: 'results_dialog.html',
  directives: [
    NgFor,
    materialDirectives,
    NgIf,
    ResultsComponent
  ],
  providers: [const ClassProvider(ScraperService), materialProviders],
)
class ResultsDialog {
  static final Logger _log = new Logger("ResultsDialog");

  bool visible = true;

  void closeButtonClick() async {
    try {
      closeTab();
    } catch (e, st) {
      _log.severe("closeButtonClick", e, st);
    }
  }

  void removeButtonClick() {}
}
