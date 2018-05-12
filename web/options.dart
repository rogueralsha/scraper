import 'package:angular/angular.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:logging/logging.dart';
import 'package:scraper/options_component.template.dart' as ng;

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(new LogPrintHandler());
//  attachXLoggerUi(true);

  runApp(ng.OptionsComponentNgFactory);

}
