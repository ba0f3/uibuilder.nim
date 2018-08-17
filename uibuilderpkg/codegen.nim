import macros, xml
import builder, types, helpers


proc makeMenu(node: XmlNode): NimNode {.compileTime.} =
  result = newStmtList()

proc gen(builder: BaseBuilder, widget: BuilderWidget, parent: BuilderWidget, parentName = ""): NimNode {.compileTime.} =
  result = newStmtList()

  if widget.kind == None:
    return

  var name = getId(widget)

  case widget.kind
  of UiWindow:
    result.add(newVarStmt(
      ident(name),
      newCall(ident("newWindow"), newStrLitNode(widget.name), newLit(widget.width), newLit(widget.height), newLit(builder.hasMenubar))
    ))
    if widget.visible:
      result.add(newCall(ident("show"), ident(name)))
  of UiBox:
    var procName = "newVerticalBox"
    if widget.orientation == HORIZONTAL:
      procName = "newHorizontalBox"
    result.add(newVarStmt(
      ident(name), newCall(ident(procName))
    ))
  else:
    discard
  if not widget.visible:
    result.add(newCall(ident("hide"), ident(name)))

  if parent.kind != None and parentName.len != 0:
    case parent.kind
    of UIWindow:
      result.add(newCall(ident("setChild"), ident(parentName), ident(name)))
    of UIBox:
      if widget.kind == UIBox:
        result.add(newCall(ident("add"), ident(parentName), ident(name), ident("true")))
      else:
        result.add(newCall(ident("add"), ident(parentName), ident(name), ident("false")))
    of UIGroup:
      result.add(newCall(newAssignment(
        newDotExpr(ident(parentName), ident("child")), ident(name)
      )))
    else:
      discard
  for child in widget.children:
    result.add builder.gen(child, widget, name)

macro build*(path: static[string]): typed =
  result = newStmtList()
  var glade = staticRead(path)
  var root = parseXml(glade)

  if root.name != "interface":
    raise newException(IOError, "invalid glade file")

  var builder = newBuilder()

  if not root.children.isNil:
    for node in root.children:
      if node.name == "object" and node.attr("class") == "GtkMenuBar":
        builder.hasMenuBar = true
        result.add makeMenu(node)

    for node in root.children:
      if node.name == "object" and node.attr("class") != "GtkMenuBar":
        var
          rootWidget: BuilderWidget
        builder.parseXml(node, rootWidget)
        result.add builder.gen(rootWidget, rootWidget)

