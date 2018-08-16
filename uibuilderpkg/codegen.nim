import macros, xml
import builder, types

export newBuilder

proc gen(p: NimNode) {.compileTime.} =
  var root: XmlNode


  return
discard """
  var root = parseXml(glade)
  if root.name != "interface":
    raise newException(IOError, "invalid glade file")

  var builder = newBuilder()

  if not root.children.isNil:
    for node in root.children:
      if node.name == "object" and node.attr("class") == "GtkMenuBar":
        builder.hasMenuBar = true
        #makeMenu(node)

    for node in root.children:
      if node.name == "object" and node.attr("class") != "GtkMenuBar":
        var rootBuilderWidget: BuilderWidget
        builder.parseXml(node, rootBuilderWidget)
"""


macro build*(x: string): typed =
  echo "calling parse on: ", x
  result = newStmtList()
  result.add(newAssignment(
    newDotExpr(ident("parseXml"), x),
    ident("root")
  )
  )




