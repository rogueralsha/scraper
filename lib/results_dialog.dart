import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:logging/logging.dart';
import 'services/scraper_service.dart';
import 'results_component.dart';
import 'services/page_stream_service.dart';
import 'globals.dart';

// AngularDart info: https://webdev.dartlang.org/angular
// Components info: https://webdev.dartlang.org/components

@Component(
  selector: 'results-dialog',
  styleUrls: <String>['results_dialog.css'],
  templateUrl: 'results_dialog.html',
  directives: [NgFor, materialDirectives, NgIf, ResultsComponent, NgClass],
  providers: [materialProviders,    const ClassProvider(PageStreamService),
  ],
)
class ResultsDialog implements OnInit {
  static final Logger _log = new Logger("ResultsDialog");

  bool visible = true;


  Map<String, bool> currentClasses = <String, bool>{"scraperResultsDialog":true,"right":true};

  final PageStreamService _pageStream;


  void setAlignment(bool leftAlign) {
    currentClasses = <String, bool>{"scraperResultsDialog":true,"right":!leftAlign,"left":leftAlign};
  }

  @override
  Future<Null> ngOnInit() async {
    _log.finest("ResultsDialog.ngOnInit start");
    try {
//      _pageStream.onPageInfo.listen((PageInfo pi) async {
//        setAlignment(pi.leftAlign);
//      });
    } on Exception catch (e, st) {
      _log.severe("ResultsDialog.ngOnInit error", e, st);
    } finally {
      _log.finest("ResultsDialog.ngOnInit end");
    }
  }

  void closeButtonClick() async {
    try {
      closeTab();
    } on Exception catch (e, st) {
      _log.severe("closeButtonClick", e, st);
    }
  }

  void removeButtonClick() {}
}
