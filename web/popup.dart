import 'package:scraper/results_component.template.dart' as ng;
import 'package:logging/logging.dart';
import 'package:scraper/services/settings_service.dart';
import 'dart:async';
import 'package:scraper/globals.dart';

final Logger _log = new Logger("popup.dart");
final SettingsService settings = new SettingsService();

Future<Null> main() async {
  Logger.root.level = await settings.getLoggingLevel();
  Logger.root.onRecord.listen(logToConsole);
  _log.info("Logging set to ${Logger.root.level.name}");

  //runApp(ng.ResultsComponentNgFactory);
}
