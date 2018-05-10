import 'dart:convert';
import 'dart:mirrors';

abstract class Serializable {

  Map<String,dynamic> toJson();

}