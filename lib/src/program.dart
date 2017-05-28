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


/// Top level statement of a program that gets inserted into a container DIV
class Program extends BeginStatement {


  /// Name of the DIV tag the workspace is inserted into
  String containerId;

  /// List of statements that can be added to a program
  List<Statement> _menu = new List<Statement>();


  /// Create and insert a new workspace in the specified DIV tag [containerId]
  Program(this.containerId)  : super("begin program", null) {
    _end.name = "end program";
    insertHtml();
  }


  /// Parse a list of statement specifications to populate the menu
  void loadStatements(List json) {
    for (var config in json) {
      if (config is Map) {
        _menu.add(new Statement.fromJSON(config));
      }
    }
  }


  /// Generate the HTML tags that get inserted into the parent DIV. 
  /// This is called automatically by the constructor
  void insertHtml() {

    // update program line numbers
    int lineNum = updateLineNumbers(1);
    _end.updateLineNumbers(lineNum + 1);

    // create the new div tag
    DivElement div = new DivElement() .. className = "tx-program";
    _renderHtml(div);
    _end._renderHtml(div);

    // insert or replace the tx-program div
    DivElement container = querySelector("$containerId .tx-program");
    if (container != null) {
      container.replaceWith(div);
    } else {
      querySelector(containerId).append(div);
    }
  }


  /// Creates a statement pulldown menu below the [expander] element
  void _openStatementMenu(Element expander, Statement after) {
    querySelectorAll('.tx-pulldown-menu').style.display = "none";
    DivElement hmenu = new DivElement() .. classes.add('tx-pulldown-menu');
    for (Statement s in _menu) {
      AnchorElement link = new AnchorElement();
      link.innerHtml = "${s.name}";
      link.href = "#";
      if (s.hasParameters) link.innerHtml += " ... ";
      hmenu.append(link);
      link.onClick.listen((e) {
        hmenu.style.display = "none";
        hmenu.remove();
        e.stopPropagation();
        Statement clone = s.clone();
        after.insertStatement(clone);
        insertHtml();
        clone._highlightLine();
      });
    }
    expander.append(hmenu);
    hmenu.style.display = "block";
  }


  // don't allow dragging or selection for the begin program statement
  void _highlightLine() { }

}



