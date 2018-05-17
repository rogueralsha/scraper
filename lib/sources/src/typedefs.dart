import 'dart:async';
import 'dart:html';
import '../../results/page_info.dart';

typedef Future<Null> LinkInfoScraper(String s, Document d);
typedef Future<Null> PageInfoScraper(
    PageInfo pi, Match m, String s, Document d);
