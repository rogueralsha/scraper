import 'dart:async';
import 'dart:html';
import 'package:angular/angular.dart';
import 'package:scraper/scraper_component.template.dart' as ng;



Future<Null> main() async {
  final Element ele = document.createElement("scraper-component");
  document.body.append(ele);
  runApp(ng.ScraperComponentNgFactory);
}

