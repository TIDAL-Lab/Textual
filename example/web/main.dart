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
import 'dart:async';
import 'dart:convert';
import 'package:Textual/textual.dart';

const millisPerBeat = 128;

class CodeBeat {

  /// display name of the instrument
  String name = "c0deb3at";

  /// version string for this instrument
  String version = "0.0.1";

  /// textual program
  Program program;

  /// used to time the vocalization
  Stopwatch clock = new Stopwatch();

  /// vocalization timer
  Timer timer;

  CBRuntime runtime = new CBRuntime();


  /// block definitions
  var blocks = [

    { 
      "name" : "hit"
    },

    { 
      "name" : "rest",
      "params" : [
        { 
          "values" : [ 1, 2, 3, 4 ], 
          "defaultValue" : 1
        }
      ]
    },

    {
      "name" : "with",
      "block" : true,
      "params" : [
        {
          "type" : "pulldown",
          "defaultValue" : "reverb",
          "values" : [ "faster", "slower", "louder", "softer", "reverb", "sustain", "distortion" ]
        }
      ]
    },

    {
      "name" : "repeat",
      "block" : true,
      "params" : [
        {
          "type" : "pulldown",
          "defaultValue" : 2,
          "values" : [ 2, 3, 4, 5, 6, 7, 8 ]
        }
      ]
    },

    {
      "name" : "chance",
      "block" : true,
      "params" : [
        {
          "name" : "value",
          "type" : "range", 
          "min" : 0, 
          "max" : 100, 
          "step" : 1, 
          "unit" : "%",
          "defaultValue" : 25
        }
      ]
    },
  ];

  var defaultProgram =
    {
      "name" : "program", 
      "block" : true,
      "children" : [ 
        { "name" : "hit" }, 
        { "name" : "rest", "params" : [ { "value" : 2 } ] } 
      ]
    };


  CodeBeat() { 
  }


  /// instantiate the instrument by inserting it inside the container DOM element
  void open(String containerId) {
    program = new Program(containerId);
    program.loadStatementDefinitions(blocks);
    program.fromJSON(defaultProgram);
    program.onProgramChanged = () {
      print(JSON.encode(program.toJSON()));
    };
  }


  void restore(Map jsonData) {
    if (jsonData.containsKey("data")) {
      program.clear();
      program.fromJSON(jsonData["data"]);
    }
  }


  Map save() {
    var json = {
      "name" : name, 
      "version" : version,
      "data" : program.toJSON()
    };
    return json;
  }


  /// called before the instrument is closed. The instrument should remove 
  /// itself from the parent DOM container
  void close() { }


  /// start playing the code 
  void play() {
    //_playButton.children[0].classes.remove("glyphicon-play");
    //_playButton.children[0].classes.add("glyphicon-pause");
    clock.start();
    timer = new Timer.periodic(const Duration(milliseconds : 32), vocalize);
  }


  /// pause the playback
  void pause() {
    clock.stop();
    if (timer != null) timer.cancel();
    //_playButton.children[0].classes.remove("glyphicon-pause");
    //_playButton.children[0].classes.add("glyphicon-play");
    program.clearTrace();
  }


  /// play / pause combined
  void playPause() {
    clock.isRunning ? pause() : play();
  }


  void vocalize(Timer timer) {
    int millis = clock.elapsedMilliseconds;
    int beat = millis ~/ millisPerBeat;
    if (beat > _lastBeat) {
      _lastBeat = beat;
      runtime.step();
    }
  }
  int _lastBeat = 0;
}


/// used to interpret codebeat programs
class CBRuntime {

  List<String> instructions = new List<String>();

  int ip = 0;

  int reg = 0;

  int curr = 0;

  List<int> stack = new List<int>();


  CBRuntime() { 
    instructions = [
      "setr",
      "18",
      "push_ip",
      "push",
      "pop", // into reg
      "dec", // reg--
      "push", // push reg
      "start",
      "40",
      "rest",
      "rest",
      "start", 
      "41",
      "play",
      "sounds/drumkit/clap.wav",
      "rest",
      "pop",
      "jump_gt" // if reg > 0: pop address and jump
    ];
  }


  void restart() {
    stack.clear();
    ip = 0;
    reg = 0;
    curr = 0;
  }


  void compile(var prog) {
  }


  void step() {
    while (ip < instructions.length) {
      String line = instructions[ip];

      if (line == "push_ip") {
        _push(ip);
      }
      else if (line == "push") {
        _push(reg);
      }
      else if (line == "setr") {
        reg = toInt(instructions[++ip]);
      }
      else if (line == "pop") {
        reg = _pop();
      }
      else if (line == "dec") {
        reg--;
      }
      else if (line == "inc") {
        reg++;
      }
      else if (line == "start") {
        curr = toInt(instructions[++ip]);
      }
      else if (line == "rest") {
        ip++;
        return;
      }
      else if (line == "play") {
        print(instructions[++ip]);
        //Sounds.playSound(instructions[++ip]);
      }

      if (line == "jump_gt") {
        int addr = _pop();
        (reg > 0) ? ip = addr : ip++;
      } else {
        ip++;
      }
    }
  }


  void _push(int v) => stack.add(v);

  int _pop() => stack.removeLast();

}





void main() {
  CodeBeat codebeat = new CodeBeat();
  codebeat.open("content");
  codebeat.play();
  /*
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
  */
}
