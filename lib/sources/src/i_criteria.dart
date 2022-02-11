import 'dart:async';
import 'dart:html';

import 'package:scraper/sources/a_source.dart';

abstract class ACriteria {
  Future<void> applyCriteria(ASource source, String url, Document doc);
}