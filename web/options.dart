import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:scraper/options_component.template.dart' as ng;
import 'package:scraper/services/settings_service.dart';
import 'dart:async';
import 'package:scraper/globals.dart';

final Logger _log = new Logger("options.dart");
final SettingsService settings = new SettingsService();

Future<Null> main() async {
  Logger.root.level = await settings.getLoggingLevel();
  Logger.root.onRecord.listen(logToConsole);
  _log.info("Logging set to ${Logger.root.level.name}");
//  attachXLoggerUi(true);

  runApp(ng.OptionsComponentNgFactory);
}
