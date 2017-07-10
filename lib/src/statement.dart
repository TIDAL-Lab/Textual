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

  /// statement display name (this might different than the action string)
  String name;

  /// internal action statement name (usually the same as 'name')
  String action;

  /// link back to the containing program
  Program program;

  /// parent of this statement in the parse tree
  BeginStatement parent;

  /// statement parameter list
  List<Parameter> params = new List<Parameter>();

  /// does this statement have any parameter arguments?
  bool get hasParameters => params.isNotEmpty;

  /// list of children of this statement (only for blocks)
  List<Statement> children = new List<Statement>();

  /// does this statement have any children?
  bool get hasChildren => children.isNotEmpty;

  /// depth of this statement in the parse tree
  int get depth => (parent == null) ? 0 : parent.depth + 1;

  /// line number gets assigned every time there's a render event
  int line = 0;

  // internal link to the DOM <div> element corresponding to this statement
  DivElement _div;


/** 
 * Default constructor
 */
  Statement(this.name, this.parent, this.program) {
    id = ++_STATEMENT_ID;
  }


/**
 * Returns a unique symbol name for this statement
 */
  String get symbol => "$action-$id";


/** 
 * Type of statement (begin, end, clause, or statement)
 */
  String get stype => "statement";


/**
 * Used to clone statements in the menu. All subclasses implement this.
 */
  Statement clone() {
    Statement s = new Statement(name, null, program);
    s.action = action;
    for (Parameter param in params) {
      s.params.add(param.clone(s));
    }
    return s;
  }


/**
 * Factory constructor used to populate the block definition menu
 */
  factory Statement.fromStatementDefinition(Map json, Program program, [ bool isClause = false ]) {
    String name = toStr(json["name"]);
    String action = toStr(json["action"], name);
    String type = toStr(json["type"], isClause ? "clause" : "statement");

    if (name == "") return null;
    
    Statement s;
    if (type == "begin") {
      s = new BeginStatement(name, null, program);
    }
    else if (type == "clause") {
      s = new ClauseStatement(name, null, program);
    }
    else if (type == "end") {
      s = new EndStatement(name, null, program);
    }
    else {
      s = new Statement(name, null, program);
    }
    s.action = action;

    // parse parameter list from JSON object
    if (json["params"] is List) {
      for (var p in json["params"]) {
        Parameter param = new Parameter.fromJSON(p, s);
        if (param != null) s.params.add(param);
      }
    }

    // parse clauses for begin statements
    if (s is BeginStatement && json["clauses"] is List) {
      for (var c in json["clauses"]) {
        s.clauses.add(new Statement.fromStatementDefinition(c, program, true));
      }
    }
    return s;
  }


/**
 * Instantiate a block from JSON (to restore programs)
 */
  factory Statement.fromJSON(Map json, Program program) {
    String name = toStr(json["name"]);
    String action = toStr(json["action"], name);

    //---------------------------------------------------------
    // look up the statement prototype and clone it
    //---------------------------------------------------------
    Statement proto = program._getStatementPrototype(action);
    Statement s;
    if (proto != null) {
      s = proto.clone();
    } else {
      s = new Statement.fromStatementDefinition(json, program);
    }

    //---------------------------------------------------------
    // parse parameter values
    //---------------------------------------------------------
    if (json["params"] != null) {
      for (int i=0; i<json["params"].length; i++) {
        if (i < s.params.length) {
          s.params[i].value = json["params"][i]["value"];
        }
      }
    }

    //---------------------------------------------------------
    // recursively parse children
    //---------------------------------------------------------
    if (json["children"] != null) {
      BeginStatement begin = null;
      for (var c in json["children"]) {
        Statement child = new Statement.fromJSON(c, program);
        child.parent = s;
        s.children.add(child);

        //-----------------------------------------------------
        // begins get matched with end statements and clauses
        //-----------------------------------------------------
        if (child is BeginStatement) {
          begin = child;
          begin.clauses.clear();
        }
        else if (child is EndStatement) {
          if (begin != null) begin.end = child;
        }
        else if (child is ClauseStatement) {
          if (begin != null) begin.clauses.add(child);
        }
      }
    }
    return s;
  }


/**
 * Generate a JSON object for this statement
 */
  dynamic toJSON() {
    var json = { 
      "id" : id, 
      "name" : name,
      "action" : action,
      "type" : stype
    };

    if (hasParameters) {
      json["params"] = [ ];
      for (Parameter param in params) {
        json["params"].add(param.toJSON());
      }
    }

    if (hasChildren) {
      json["children"] = [ ];
      for (Statement child in children) {
        json["children"].add(child.toJSON());
      }
    }
    return json;
  }


  /// adds a visual trace to the statement with the given id number. 
  /// returns true if the statement id was matched
  bool traceStatement(int id) {
    if (this.id == id) {
      _div.classes.add("tx-trace");
      return true;
    } else {
      for (Statement s in children) {
        if (s.traceStatement(id)) return true;
      }
    }
    return false;
  }


/**
 * Resets line numbers after insertion or deletion of a statement
 */ 
  int _updateLineNumbers(int lineNum) {
    line = lineNum;
    for (Statement child in children) {
      lineNum = child._updateLineNumbers(lineNum + 1);
    }
    return lineNum;
  }


/**
 * Adds a new statement to the program right after this statement
 */
  void _insertStatement(Statement add) {
    if (parent != null) {
      parent._addChild(add, this);
      if (add is BeginStatement) {
        ControlStatement cs = add;
        for (ClauseStatement clause in add.clauses) {
          parent._addChild(clause, cs);
          cs = clause;
        }
        parent._addChild(add.end, cs);
      }
      program._programChanged(add);
    }
  }


/** 
 * Inserts a new child statement after the existing child
 */
  void _addChild(Statement newChild, [ Statement afterChild = null]) {
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

    if (s is EndStatement || s is ClauseStatement) return;

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
        for (ClauseStatement clause in s.clauses) {
          children.remove(clause);
        }
        children.remove(s.end);
      }

      for (Statement child in s.children) child.parent = this;
      children.insertAll(index, s.children);
      s.children.clear();
    }
  }



  void _highlightLine() {
    querySelectorAll(".tx-line").classes.remove("tx-highlight");
    querySelectorAll('.tx-pulldown-menu').style.display = "none";
    querySelectorAll(".tx-add-line").style.display = "none";
    _div.classes.add("tx-highlight");
    querySelector("#tx-expander-$id").style.display = "inline-block";
  }


  num get _insertionPoint {
    if (_div != null) {
      var rect = _div.getBoundingClientRect();
      return rect.bottom + rect.height;
    } else if (this == program.root && hasChildren && children[0]._div != null) {
      var rect = children[0]._div.getBoundingClientRect();
      return rect.bottom;
    } else {
      return 100000;
    }
  }


  /// find the insertion point for a statement being dragged.
  /// the dragged statement gets inserted after the insertion point.
  Statement _findInsertionPoint(num ty) {
    if (ty <= _insertionPoint) return this;

    for (Statement child in children) {
      Statement result = child._findInsertionPoint(ty);
      if (result != null) return result;
    }
    return null;
  }


  /// drag start event
  void _dragStart(var event) {
    event.dataTransfer.setData("statement", id);
    querySelectorAll(".tx-add-line").style.display = "none";
    querySelectorAll('.tx-pulldown-menu').style.display = "none";
    _div.classes.add("dragging");
  }


  /// drag end event
  void _dragEnd(var event) {
    if (_insertion != this && _insertion != null) {
      if (this is! ControlStatement && this is! EndStatement) {
        parent.removeChild(this);
        if (_insertion is ControlStatement || _insertion == program.root) {
          _insertion._addChild(this);
        } else {
          _insertion.parent._addChild(this, _insertion);
        }
        program._programChanged(this);
        program._renderHtml();
      }
    }
    _insertion = null;
    _div.classes.remove("dragging");
    querySelectorAll(".tx-insertion-line").classes.remove("show");
  }


  /// drag over event
  void _dragOver(var event) {
    _insertion = program._findInsertionPoint(event.client.y);
    if (_insertion != null) {
      DivElement el = querySelector("#tx-insertion-${_insertion.id}");
      if (el != null && !el.classes.contains("show")) {
        querySelectorAll(".tx-insertion-line").classes.remove("show");
        el.classes.add("show");
      }
    }
  }
  static Statement _insertion = null;



/**
 * Messy HTML DOM stuff here!
 */
  void _renderHtml(DivElement pdiv) {

    // container for the statement line itself
    _div = new DivElement() .. className = "tx-line";
    _div.id = "tx-line-$id";
    _div.appendHtml("<div id='tx-line-number-$id' class='tx-line-number'>${line}</div>");
    if (this is ControlStatement || this is EndStatement) {
      _div.appendHtml("<div class='tx-line-sort'></div>");
    } else {
      _div.appendHtml("<div class='tx-line-sort'><span class='fa fa-sort'></span></div>");
    }

    // statement name 
    DivElement stmt = new DivElement() .. className = "tx-statement-name";
    stmt.innerHtml = name;
    stmt.style.paddingLeft = "${(depth - 1) * 1.2}em";
    _div.append(stmt);

    // parameter pulldowns 
    if (hasParameters) {
      _div.appendHtml("<span> (</span>");
      for (int i=0; i<params.length; i++) {
        Parameter p = params[i];
        _div.append(p._renderHtml());
        if (i >= 0 && i < params.length - 1) {
          _div.appendHtml("<span>, </span>");
        }
      }
      _div.appendHtml("<span>)</span>");
    }
    if (this is ControlStatement) {
      _div.appendHtml("<span>:</span>");
    }

    // delete button
    if (this is! EndStatement && this is! ClauseStatement) {
      ButtonElement del = new ButtonElement() .. className = "tx-delete-line fa fa-times-circle";
      _div.append(del);

      // delete a line when you click on the button
      del.onClick.listen((e) {
        if (parent != null) {
          parent.removeChild(this);
        }
        program._programChanged(this);
        program._renderHtml();
        e.stopPropagation();
      });
    }

    // highlight the line when you click on it
    _div.draggable = (this is! ControlStatement && this is! EndStatement);
    _div.onClick.listen((e) { _highlightLine(); });
    _div.onDragStart.listen(_dragStart);
    _div.onDragEnd.listen(_dragEnd);
    _div.onDragOver.listen(_dragOver);

    // wrapper contains the expander as well
    DivElement wrapper = new DivElement() .. classes.add("tx-line-wrapper");
    wrapper.id = "tx-line-wrapper-$id";
    wrapper.draggable = false;  // only draggable when you're highlighted
    wrapper.append(_div);

    // insertion point
    num indent = 2 + ((this is ControlStatement) ? depth : depth - 1) * 1.2;

    DivElement insert = new DivElement() .. className = "tx-insertion-line";
    insert.id = "tx-insertion-$id";
    insert.style.marginLeft = "${indent}em";
    wrapper.append(insert);

    // expander button
    ButtonElement expander = new ButtonElement() .. className = "tx-add-line fa fa-caret-down";
    expander.id = "tx-expander-$id";
    expander.dataset["line-number"] = "$line";
    expander.style.marginLeft = "${indent}em";


    // show the expander button if this is an empty begin/end bracket
    if (this is ControlStatement && !hasChildren) {
      expander.style.display = "inline-block";
    }

    // show the expander button if this is the last statement in the program
    if (program._isLastStatement(this)) {
      expander.style.display = "inline-block";
    }

    expander.onClick.listen((e) {
      program._openStatementMenu(expander, this);
      e.stopPropagation();
    });

    wrapper.append(expander);
    pdiv.append(wrapper);

    for (Statement child in children) {
      child._renderHtml(pdiv);
    }
  }
}


/**
 * Generic superclass for all control statements (begin and clause).
 */
abstract class ControlStatement extends Statement {

  ControlStatement(String name, Statement parent, Program program) :
    super(name, parent, program);


/**
 * Adds a new statement to the program right after this statement
 */
  void _insertStatement(Statement add) {
    _addChild(add);
    if (add is BeginStatement) {
      ControlStatement cs = add;
      for (ClauseStatement clause in add.clauses) {
        _addChild(clause, cs);
        cs = clause;
      }
      _addChild(add.end, cs);
    }
    program._programChanged(add);
  }
}


/** 
 * BeginStatements have children with a begin/end block structure
 */
class BeginStatement extends ControlStatement {

  /// corresponding end statement
  EndStatement end;

  /// intermediate clauses (e.g. else if, else, otherwise)
  List<ClauseStatement> clauses = new List<ClauseStatement>();


  BeginStatement(String name, Statement parent, Program program) : 
    super(name, parent, program) 
  {
    end = new EndStatement("end $name", parent, program);
    end.action = "end-$name";
  }


  BeginStatement clone() {
    BeginStatement begin = new BeginStatement(name, null, program);
    begin.action = action;
    for (Parameter param in params) {
      begin.params.add(param.clone(begin));
    }
    for (ClauseStatement clause in clauses) {
      begin.clauses.add(clause.clone());
    }
    return begin;
  }

  String get stype => "begin";
}


/**
 * ClauseStatements fall between begin and end statements. They include
 * things like 'else', 'else if', and so on.
 */
class ClauseStatement extends ControlStatement {

  ClauseStatement(String name, Statement parent, Program program) : 
    super(name, parent, program);


  ClauseStatement clone() {
    ClauseStatement clause = new ClauseStatement(name, null, program);
    clause.action = action;
    for (Parameter param in params) {
      clause.params.add(param.clone(clause));
    }
    return clause;
  }

  String get stype => "clause";
}


/** 
 * EndStatements match begin statements
 */
class EndStatement extends Statement {

  EndStatement(String name, Statement parent, Program program) : 
    super(name, parent, program);

  String get stype => "end";
}




