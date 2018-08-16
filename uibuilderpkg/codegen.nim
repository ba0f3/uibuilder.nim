import macros, xml
import builder, types, helpers


proc makeMenu(node: XmlNode): NimNode {.compileTime.} =
  result = newStmtList()

proc gen(builder: BaseBuilder, widget: BuilderWidget, ids: var seq[string]): NimNode {.compileTime.} =
  result = newStmtList()

  if widget.kind == None:
    return

  var name = getId(widget, ids)

  case widget.kind
  of UiWindow:
    result.add(newVarStmt(
      ident(name),
      newCall(ident("newWindow"), newStrLitNode(widget.name), newLit(widget.width), newLit(widget.height), newLit(builder.hasMenubar))
    ))
    if widget.visible:
      result.add(newCall(ident("show"), ident(name)))
  else:
    discard

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
          ids: seq[string] = @[]
        builder.parseXml(node, rootWidget)
        result.add builder.gen(rootWidget, ids)

