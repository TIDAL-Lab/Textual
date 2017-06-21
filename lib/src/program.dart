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

  /// root elements for the program parse tree
  List<Statement> children = new List<Statement>();


  /// callback for program changed events
  Function onProgramChanged = null;


  /// List of statements that can be added to a program
  List<Statement> _menu = new List<Statement>();


  /// Create and insert a new workspace in the specified DIV tag [containerId]
  Program(this.containerId) {
    children.add(new BeginStatement("beat", null, this));
    renderHtml();
  }


  /// Parse a list of statement specifications to populate the menu
  void initMenu(List json) {
    for (var config in json) {
      if (config is Map) {
        _menu.add(new Statement.fromJSON(config, this));
      }
    }
  }


  /// Generate the HTML tags that get inserted into the parent DIV. 
  /// This is called automatically by the constructor
  void renderHtml() {

    // update program line numbers
    int lineNum = 1;
    for (Statement root in children) {
      lineNum = root._updateLineNumbers(lineNum);
      if (root is BeginStatement) root._end.line = lineNum + 1;
    }

    // create the new div tag
    DivElement div = new DivElement() .. className = "tx-program";

    for (Statement root in children) {
      root._renderHtml(div);
      if (root is BeginStatement) root._end._renderHtml(div);
    }

    // insert or replace the tx-program div
    DivElement container = querySelector("$containerId .tx-program");
    if (container != null) {
      container.replaceWith(div);
    } else {
      querySelector(containerId).append(div);
    }
  }


  /// generates a JSON representation of this program
  dynamic toJSON() {
    var json = [];
    for (Statement root in children) {
      json.add(root.toJSON());
    }
    return json;
  }

  /// called whenever the program is changed (fires callback)
  void _programChanged(Statement changed) {
    if (onProgramChanged != null) {
      Function.apply(onProgramChanged, []);
    }
  }


  /// Creates a statement pulldown menu below the [expander] element
  void openStatementMenu(Element expander, Statement after) {
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
        after.insertStatement(clone);
        renderHtml();
        clone._highlightLine();
        e.stopPropagation();
      });
    }
    expander.append(hmenu);
    hmenu.style.display = "block";
  }
}



