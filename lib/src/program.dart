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


/// Contains all of the program statements
class Program {


  /// Name of the DIV tag the workspace is inserted into
  String containerId;


  /// single root element for the entire program
  BeginStatement root;

  /// callback for program changed events
  Function onProgramChanged = null;


  /// callback for parameter changed events
  Function onParameterChanged = null;


  /// used to generate code based on Textual statements
  Map<String, Function> _generators = new Map<String, Function>();


  /// List of statements that can be added to a program
  List<Statement> _menu = new List<Statement>();


  Program() { 
    root = new BeginStatement("<root>", null, this);
  }


  /// erase the current program (doesn't fire a program changed event) 
  void clear() {
    root.children.clear();
    _renderHtml();
  }


  /// Parse a list of statement specifications to populate the menu
  void loadStatementDefinitions(List json) {
    for (var config in json) {
      if (config is Map) {
        _menu.add(new Statement.fromStatementDefinition(config, this));
      }
    }
  }


  /// generates a JSON representation of this program
  dynamic toJSON() {
    return root.toJSON();
  }


  /// load a program based on a previously saved JSON object
  void fromJSON(var json) {
    clear();
    root = new Statement.fromJSON(json, this);
    _renderHtml();
  }


  /// adds a visual trace to the statement with the given id number. 
  /// returns true if the statement id was matched
  bool traceStatement(int id) {
    //querySelectorAll(".tx-line").classes.remove("tx-trace");
    return root.traceStatement(id);
  }


  /// clear any trace
  void clearTrace() {
    querySelectorAll(".tx-line").classes.remove("tx-trace");
  }


  /// add a code generator for a block type (maps to a statements name or action)
  void addGenerator(String action, Function generator) {
    _generators[action] = generator;
  }


  /// translates code using generator functions
  String generateCode() {
    StringBuffer out = new StringBuffer();
    _generate(root, out);
    return out.toString();
  }


  void _generate(Statement s, StringBuffer out) {
    if (_generators.containsKey(s.action)) {
      out.writeln(Function.apply(_generators[s.action], [ s ]));
    }
    for (Statement child in s.children) _generate(child, out);
  }


  /// Generate the HTML tags that get inserted into the parent DIV. 
  /// This is called automatically by the constructor
  void renderHtml(String containerId) {
    this.containerId = containerId;
    _renderHtml();
  }


  /// find the insertion point for a statement being dragged.
  /// the dragged statement gets inserted after the insertion point.
  Statement _findInsertionPoint(num ty) {
    if (root.children.isEmpty) return root;
    Statement result = root._findInsertionPoint(ty);
    return (result == null) ? root.children.last : result;
  }


  /// find a block prototype from the menu
  Statement _getStatementPrototype(String name) {
    for (Statement s in _menu) {
      if (s.name == name) return s;
    }
    return null;
  }


  void _renderHtml() {

    if (containerId != null && querySelector("#$containerId") != null) {

      // update program line numbers
      int lineNum = 0;
      for (Statement s in root.children) {
        lineNum = s._updateLineNumbers(lineNum + 1);
      }

      // create the new div tag
      DivElement div = new DivElement() .. className = "tx-program";

      DivElement insert = new DivElement() .. className = "tx-insertion-line";
      insert.id = "tx-insertion-${root.id}";
      insert.style.marginLeft = "2em";
      div.append(insert);

      for (Statement s in root.children) {
        s._renderHtml(div);
      }

      div.onClick.listen((e) {
        querySelectorAll('.tx-pulldown-menu').style.display = "none";
      });


      // insert or replace the tx-program div
      DivElement container = querySelector("#$containerId .tx-program");
      if (container != null) {
        container.replaceWith(div);
      } else {
        querySelector("#$containerId").append(div);
      }
    }
  }


  /// called whenever the program is changed (fires callback)
  void _programChanged(Statement changed) {
    if (onProgramChanged != null) {
      Function.apply(onProgramChanged, []);
    }
  }


  /// called whenever a parameter is changed 
  void _parameterChanged(Parameter param) {
    if (onParameterChanged != null) {
      Function.apply(onParameterChanged, []);
    }
  }


  /// is [s] the last statement in the program?
  bool _isLastStatement(Statement s) {
    return (root.children.last == s);
  }


  /// Creates a statement pulldown menu below the [expander] element
  void _openStatementMenu(Element expander, Statement after) {
    querySelectorAll('.tx-pulldown-menu').style.display = "none";
    DivElement hmenu = new DivElement() .. classes.add('tx-pulldown-menu');
    for (Statement s in _menu) {
      AnchorElement link = new AnchorElement(href : "#") .. innerHtml = "${s.name}";
      if (s.hasParameters) link.innerHtml += " ... ";
      hmenu.append(link);
      link.onClick.listen((e) {
        hmenu.style.display = "none";
        hmenu.remove();
        Statement clone = s.clone();
        after._insertStatement(clone);
        _renderHtml();
        clone._highlightLine();
        e.stopPropagation();
      });
    }
    expander.append(hmenu);
    hmenu.style.display = "block";
  }
}



