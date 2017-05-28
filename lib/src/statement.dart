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


/**
 * Base class for all language statements
 */
class Statement {

  /// used to generate unique statement IDs
  static int _STATEMENT_ID = 0;

  /// unique statement id number
  int id;

  /// statement display name  (this might different than the action string)
  String name;

  //// internal action statement name (usually the same as 'name')
  String action;

  /// parent of this statement in the parse tree
  BeginStatement parent;

  /// satement parameter list
  List<Parameter> params = new List<Parameter>();

  /// does this statement have any parameter arguments?
  bool get hasParameters => params.isNotEmpty;

  /// list of children of this statement (only for blocks)
  List<Statement> children = new List<Statement>();

  /// does this statement have any children?
  bool get hasChildren => children.isNotEmpty;

  /// depth of this statement in the parse tree
  int get depth => (parent == null) ? 0 : parent.depth + 1;

  /// topmost parent of this statement (Program statement)
  Program get root {
    if (this is Program) {
      return this;
    } else if (parent != null) {
      return parent.root;
    } else {
      return null;
    }
  }

  // internal link to the DOM <div> element corresponding to this statement
  DivElement _div;

  // internal line number gets assigned every time there's a render event
  int _line = 0;

/** 
 * Default constructor
 */
  Statement(this.name, this.parent) {
    id = ++_STATEMENT_ID;
  }


/**
 * Used to clone statements in the menu. All subclasses implement this.
 */
  Statement clone() {
    Statement s = new Statement(name, null);
    s.action = action;
    s.parent = null;
    for (Parameter param in params) {
      s.params.add(param.clone());
    }
    return s;
  }


/**
 * Factory constructor used to populate the menu
 */
  factory Statement.fromJSON(Map json) {
    String name = toStr(json["name"]);
    String action = toStr(json["action"]);
    String stype = toStr(json["type"]);
    bool block = toBool(json["block"]);

    if (name == "") return null;
    
    Statement s;
    if (block) {
      s = new BeginStatement(name, null);
    } else {
      s = new Statement(name, null);
    }

    // parse parameter list from JSON object
    if (json["params"] != null && json["params"] is List) {
      for (var p in json["params"]) {
        Parameter param = new Parameter.fromJSON(p);
        if (param != null) s.params.add(param);
      }
    }

    return s;
  }


/**
 * Resets line numbers after insertion or deletion of a statement
 */ 
  int updateLineNumbers(int lineNum) {
    _line = lineNum;
    for (Statement child in children) {
      lineNum = child.updateLineNumbers(lineNum + 1);
    }
    return lineNum;
  }


/**
 * Adds a new statement to the program right after this statement
 */
  void insertStatement(Statement add) {
    parent.addChild(add, this);
    if (add is BeginStatement) {
      parent.addChild(add._end, add);
    }
  }


  void _clearHighlight() {
    _div.draggable = false;
    for (Statement child in children) {
      child._clearHighlight();
    }
  }


  void _highlightLine() {
    root._clearHighlight();
    querySelectorAll(".tx-line").classes.remove("tx-highlight");
    querySelectorAll('.tx-pulldown-menu').style.display = "none";
    querySelectorAll(".tx-add-line").style.display = "none";
    _div.classes.add("tx-highlight");
    _div.draggable = true;
    querySelector("#tx-expander-$id").style.display = "inline-block";
  }


/**
 * Messy HTML DOM stuff here!
 */
  void _renderHtml(DivElement pdiv) {

    // container for the statement line itself
    _div = new DivElement() .. classes.add("tx-line");
    _div.id = "tx-line-$id";
    _div.appendHtml("<div id='tx-line-number-$id' class='tx-line-number'>${_line}</div>");
    _div.appendHtml("<div class='tx-line-sort'><span class='fa fa-sort'></span></div>");

    // statement name 
    DivElement stmt = new DivElement() .. classes.add("tx-statement-name");
    stmt.innerHtml = name;
    stmt.style.paddingLeft = "${depth * 1.2}em";
    _div.append(stmt);

    // parameter pulldowns 
    for (Parameter p in params) {
      _div.append(p._renderHtml());
    }

    // delete button
    ButtonElement del = new ButtonElement() .. className = "tx-delete-line fa fa-times-circle";
    _div.append(del);

    // highlight the line when you click on it
    _div.onClick.listen((e) { _highlightLine(); });

    // delete a line when you click on the button
    del.onClick.listen((e) {
      if (parent != null) {
        parent.removeChild(this);
        root.insertHtml();
      }
      e.stopPropagation();
    });

    // wrapper contains the expander as well
    DivElement wrapper = new DivElement() .. classes.add("tx-line-wrapper");
    wrapper.id = "tx-line-wrapper-$id";
    wrapper.draggable = false;  // only draggable when you're highlighted
    wrapper.append(_div);

    // expander button
    ButtonElement expander = new ButtonElement() .. className = "tx-add-line fa fa-caret-down";
    expander.id = "tx-expander-$id";
    expander.dataset["line-number"] = "$_line";
    if (this is BeginStatement) {
      expander.style.marginLeft = "${4 + (depth + 1) * 1.2}em";
    } else {
      expander.style.marginLeft = "${4 + depth * 1.2}em";
    }

    // show the expander button if this is an empty begin/end bracket
    if (this is BeginStatement && !hasChildren) {
      expander.style.display = "inline-block";
    }

    expander.onClick.listen((e) {
      root._openStatementMenu(expander, this);
    });

    wrapper.append(expander);
    pdiv.append(wrapper);

    for (Statement child in children) {
      child._renderHtml(pdiv);
    }
  }
}


/** 
 * BeginStatements have children with a begin/end block structure
 */
class BeginStatement extends Statement {

  /// corresponding end statement
  EndStatement _end;


  BeginStatement(String name, Statement parent) : super(name, parent) {
    _end = new EndStatement("end $name", parent);
  }


  BeginStatement clone() {
    BeginStatement begin = new BeginStatement(name, null);
    begin.action = action;
    for (Parameter param in params) {
      begin.params.add(param.clone());
    }
    return begin;
  }


/**
 * Inserts a new statement as the first child of this block
 */
  void insertStatement(Statement add) {
    addChild(add);
    if (add is BeginStatement) {
      addChild(add._end, add);
    }
  }


/** 
 * Inserts a new child statement after the existing child
 */
  void addChild(Statement newChild, [ Statement afterChild = null]) {
    newChild.parent = this;
    if (afterChild != null) {
      for (int i=0; i<children.length; i++) {
        if (children[i] == afterChild) {
          children.insert(i + 1, newChild);
          return;
        }
      }
      children.add(newChild);
    } else {
      children.insert(0, newChild);
    }
  }


/**
 * Removes a child from the block. If the child also has children, 
 * they are moved up the hierarchy to become new children of the parent block.
 */
  void removeChild(Statement s) {

    // find the child index
    int index = -1;
    for (int i=0; i<children.length; i++) {
      if (children[i] == s) {
        index = i;
        break;
      }
    }

    if (index >= 0) {
      children.removeAt(index);

      // move grandchildren up a level
      if (s is BeginStatement) {
        children.remove(s._end);
      }

      for (Statement child in s.children) child.parent = this;
      children.insertAll(index, s.children);
      s.children.clear();
    }
  }
}


/** 
 * EndStatements match begin statements
 */
class EndStatement extends Statement {

  EndStatement(String name, Statement parent) : super(name, parent);

  void _highlightLine() {
    // don't allow delete or highligh for end statements
  }

}




