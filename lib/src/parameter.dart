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
part of Textual;


class Parameter {

  static int _PARAM_ID = 0;

  /// internal unique id number
  int id;

  /// statement that owns this parameter
  Statement statement;

  /// name of the parameter (OK if null)
  String name;

  /// current value of the parameter specified in the program text
  var value;

  /// array of possible values (may not be used for all param types)
  var values = [];

  /// HTML DOM element that holds the current value
  SpanElement _span;

  String unit = "";


  Parameter(this.name, this.statement) {
    id = _PARAM_ID++;
  }


  Parameter clone(Statement owner) {
    Parameter p = new Parameter(name, owner);
    for (var v in values) p.values.add(v);
    p.value = value;
    p.unit = unit;
    return p;
  }


/**
 * Factory constructor created from JSON spec
 */
  factory Parameter.fromJSON(Map json, Statement owner) {
    String name = json['name'];
    if (json.containsKey("type") && json["type"] == "range") {
      return new RangeParameter.fromJSON(json, owner);
    } 

    else if (json.containsKey("type") && json["type"] == "string") {
      return new StringParameter.fromJSON(json, owner);
    }

    else {
      Parameter p = new Parameter(name, owner);
      if (json.containsKey('values') && json['values'] is List) {
        for (var v in json['values']) {
          p.values.add(v);
        }
        if (p.values.length > 0) p.value = p.values[0];
      }
      if (json.containsKey('defaultValue')) {
        p.value = json['defaultValue'];
      }
      p.unit = toStr(json['unit']);
      return p;
    }
  }


/**
 * Exports this parameter to JSON
 */
  dynamic toJSON() {
    var json = {
      "id" : id,
      "name" : name,
      "unit" : unit,
      "value" : value
    };
    return json;
  }


  Element _renderHtml() {
    DivElement div = new DivElement();
    div.classes.add("tx-parameter");
    _span = new SpanElement() .. innerHtml = "$value$unit";
    div.append(_span);

    ButtonElement button = new ButtonElement() .. className = "tx-param-button fa fa-caret-down";
    //div.append(button);

    DivElement menu = _renderMenu();
    div.append(menu);

    _span.onClick.listen((e) { 
      if (menu.style.display == "block") {
        querySelectorAll('.tx-pulldown-menu').style.display = "none";
      } else {
        querySelectorAll('.tx-pulldown-menu').style.display = "none";
        menu.style.display = "block"; 
      }
      e.stopPropagation();
    });
    button.onClick.listen((e) { 
      if (menu.style.display == "block") {
        querySelectorAll('.tx-pulldown-menu').style.display = "none";
      } else {
        querySelectorAll('.tx-pulldown-menu').style.display = "none";
        menu.style.display = "block"; 
      }
      e.stopPropagation();
    });

    return div;
  }


  DivElement _renderMenu() {
    DivElement menu = new DivElement() .. classes.add('tx-pulldown-menu');
    for (var v in values) {
      AnchorElement link = new AnchorElement();
      link.innerHtml = "$v$unit";
      link.href = "#";
      if (v == value) link.classes.add('selected');
      menu.append(link);
      link.onClick.listen((e) {
        value = v;
        _span.innerHtml = "$v$unit";
        querySelectorAll(".tx-pulldown-menu a").classes.remove("selected");
        link.classes.add("selected");
        menu.style.display = "none";
        statement.program._parameterChanged(this);
        e.preventDefault();
        e.stopPropagation();
      });
    }
    return menu;
  }
}


class RangeParameter extends Parameter {

  num _min = 0.0;
  num _max = 100.0;
  num _step = 1.0;

  RangeParameter(String name, Statement owner) : super(name, owner);


  RangeParameter.fromJSON(Map data, Statement owner) : super("", owner) {
    name = data["name"];
    _min = toNum(data["min"], 0);
    _max = toNum(data["max"], 10);
    _step = toNum(data["step"], 1);
    unit = toStr(data["unit"], "");
    value = toNum(data["defaultValue"], 5);
    //randomOption = toBool(data["random"], false);
    //_low = new RangeThumb(initialValue, this);
    //_high = new RangeThumb(maxValue, this);
    //_high.visible = false;
  }


/**
 * Exports this parameter to JSON
 */
  dynamic toJSON() {
    var json = {
      "type" : "range",
      "id" : id,
      "name" : name,
      "unit" : unit,
      "value" : value
    };
    return json;
  }


  RangeParameter clone(Statement owner) {
    RangeParameter p = new RangeParameter(name, owner);
    p._min = _min;
    p._max = _max;
    p._step = _step;
    p.unit = unit;
    p.value = value;
    return p;
  }


  DivElement _renderMenu() {
    DivElement menu = new DivElement() .. classes.add('tx-pulldown-menu');
    menu.draggable = false;
    menu.appendHtml("<label for='tx-range-param-$id' id='tx-range-label-$id' class='tx-range-label'>$name: $value$unit</label>");
    RangeInputElement range = new RangeInputElement() .. className = 'tx-range-slider';
    range.id = "tx-range-param-$id";
    range.min = "$_min";
    range.max = "$_max";
    range.step = "$_step";
    range.valueAsNumber = value;
    menu.append(range);

    menu.appendHtml("<div class='tx-range-label max'>$_max</div>");
    menu.appendHtml("<div class='tx-range-label'>$_min</div>");

    range.onChange.listen((e) {
      value = range.valueAsNumber;
      _span.innerHtml = "$value$unit";
      querySelector("#tx-range-label-$id").innerHtml = "$name: $value$unit";
      statement.program._parameterChanged(this);
      e.stopPropagation();
      e.preventDefault();
    });

    range.onInput.listen((e) {
      value = range.valueAsNumber;
      _span.innerHtml = "$value$unit";
      querySelector("#tx-range-label-$id").innerHtml = "$name: $value$unit";
    });

    return menu;
  }  
}



class StringParameter extends Parameter {

  StringParameter(String name, Statement owner) : super(name, owner);


  StringParameter.fromJSON(Map data, Statement owner) : super("", owner) {
    value = toStr(data["defaultValue"]);
    unit = toStr(data["unit"], "");
  }


  StringParameter clone(Statement owner) {
    StringParameter p = new StringParameter(name, owner);
    p.value = value;
    p.unit = unit;
    return p;
  }


  Element _renderHtml() {

    DivElement div = new DivElement() .. className = "tx-parameter";

    InputElement input = new InputElement() .. className = "tx-string-param";
    input.value = value;

    div.append(input);

    input.onClick.listen((e) { 
      querySelectorAll('.tx-pulldown-menu').style.display = "none";
      e.stopPropagation();
    });

    input.onChange.listen((e) {
      statement.program._parameterChanged(this);
    });

    input.onInput.listen((e) {
      value = input.value;
    });
    return div;
  }  
}
