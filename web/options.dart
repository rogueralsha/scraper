import 'package:angular/angular.dart';
import 'package:chrome/chrome_ext.dart' as chrome;
import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(new LogPrintHandler());
//  attachXLoggerUi(true);

  //runApp(ng.AppComponentNgFactory);

}
