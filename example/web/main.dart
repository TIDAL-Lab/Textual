/*
 * TunePad
 *
 * Michael S. Horn
 * Northwestern University
 * michael-horn@northwestern.edu
 * Copyright 2016, Michael S. Horn
 *
 * This project was funded by the National Science Foundation (grant DRL-1612619).
 * Any opinions, findings and conclusions or recommendations expressed in this
 * material are those of the author(s) and do not necessarily reflect the views
 * of the National Science Foundation (NSF).
 */
library TextualExample;

import 'dart:html';
import 'dart:convert';
import 'package:Textual/textual.dart';


void main() {
  Program program = new Program("#content");
  HttpRequest.getString("blocks.json").then((jsonString) {
    program.loadStatementDefinitions(JSON.decode(jsonString));
    jsonString = '[{"id":1,"name":"beat","children":[{"id":22,"name":"strum"},{"id":23,"name":"slap"},{"id":24,"name":"with","params":[{"id":6,"name":null,"unit":"","value":"softer"}],"children":[{"id":26,"name":"rest","params":[{"type":"range","id":7,"name":"beats","unit":"","value":4}]},{"id":27,"name":"chance","params":[{"type":"range","id":8,"name":"value","unit":"%","value":54}],"children":[{"id":31,"name":"stop"}]}]}]}]';
    program.fromJSON(JSON.decode(jsonString));
    program.traceStatement(23);
  });


  program.onProgramChanged = () {
    print(JSON.encode(program.toJSON()));
  };
}
