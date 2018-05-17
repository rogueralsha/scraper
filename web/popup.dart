import 'package:scraper/results_component.template.dart' as ng;
import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:logging_handlers/browser_logging_handlers.dart';
import 'package:logging/logging.dart';
import 'package:scraper/services/settings_service.dart';
import 'dart:async';

final Logger _log = new Logger("popup.dart");
final SettingsService settings = new SettingsService();

Future<Null> main() async {
  Logger.root.level = await settings.getLoggingLevel();
  Logger.root.onRecord.listen(new LogPrintHandler());
  _log.info("Logging set to ${Logger.root.level.name}");

  //runApp(ng.ResultsComponentNgFactory);
}
