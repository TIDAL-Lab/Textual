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
library Textual;

import 'dart:html';
import 'dart:convert';

part 'src/parameter.dart';
part 'src/program.dart';
part 'src/statement.dart';



/// Parses an int from an object (usually a string)
int toInt(var d, [ int defalutValue = 0 ]) {
  if (d == null) {
    return defalutValue;
  } 
  else if (d is int) {
    return d;
  } 
  else {
    try {
      return int.parse(d.toString());
    } on Exception {
      return defalutValue;
    }
  }
}


/// parses an int from an object (usually a string)
num toNum(var d, [ num defaultValue = 0 ]) {
  if (d == null) {
    return defaultValue;
  } 
  else if (d is num) {
    return d;
  } 
  else {
    try {
      return num.parse(d.toString());
    } on Exception {
      return defaultValue;
    }
  }
}


/// parses a bool from an object (usually string or bool)
bool toBool(var b, [bool defaultValue = false ]) {
  if (b == null) {
    return defaultValue;
  }
  else if (b is bool) {
    return b;
  }
  else {
    String s = b.toString();
    if (s.toLowerCase() == "true" || s.toLowerCase() == "t") {
      return true;
    } 
    else if (s.toLowerCase() == "false" || s.toLowerCase() == "f") {
      return false;
    }
  }
  return defaultValue;
}


/// converts a value to a string
String toStr(var o, [ String defaultValue = "" ]) {
  return (o == null) ? defaultValue : o.toString();
}


/// Returns a random, normally distributed number (mean = 0; SD = 1)
double nextGaussian() { 
  double c, x1, x2, rad;
  do {
    x1 = 2 * rand.nextDouble() - 1;
    x2 = 2 * rand.nextDouble() - 1;
    rad = x1 * x1 + x2 * x2;
  } while (rad >= 1 || rad == 0);
  c = sqrt(-2 * log(rad) / rad);
  return x1 * c;
}

