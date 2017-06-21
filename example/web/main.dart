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
    program.initMenu(JSON.decode(jsonString));
  });

  program.onProgramChanged = () {
    print(JSON.encode(program.toJSON()));
  };
}
