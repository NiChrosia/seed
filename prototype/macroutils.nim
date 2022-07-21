import std/[macros]

proc echoNode*(node: NimNode) =
    echo node.treeRepr()

macro assign*(value: typed, fields: varargs[typed]): untyped =
  ## automagically assigns fields to value, in the following syntax:
  ## object.field = field
  ## this takes advantage of the fact that assignments often have
  ## a name shared between property and variable containing the
  ## corresponding property
  
  # value:
  #   Sym "[value name]"
  # fields:
  #   ArgList
  #     Ident "[field name]"
  
  result = newStmtList()
  
  for field in fields:
    let access = newDotExpr(value, field)
    let assignment = newAssignment(access, field)
    
    result.add assignment
    # assignment:
    #   Asgn
    #     DotExpr
    #       Ident "[value name]"
    #       Ident "[field name]"
    #     Ident "[field name]"