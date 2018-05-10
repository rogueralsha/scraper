import 'package:angular/angular.dart';

import 'package:scraper/results_component.template.dart' as ng;
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:logging_handlers/browser_logging_handlers.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(new LogPrintHandler());

  runApp(ng.ResultsComponentNgFactory);

}
