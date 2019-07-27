import 'package:logging/logging.dart';

class SourceArtistSetting {
  static final Logger _log = new Logger("SourceArtistSetting");
  bool promptForDownload = false;

  SourceArtistSetting();

  SourceArtistSetting.fromMap(Map data) {
    _log.finest("SourceArtistSetting.fromMap($data)");
    if(data==null)
      return;
    this.promptForDownload = data["promptForDownload"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> output = <String, dynamic>{};
    output["promptForDownload"] = promptForDownload;
    return output;
  }
}
