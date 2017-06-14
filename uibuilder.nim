import ui, os, streams, xmlparser, xmltree, strutils, tables, strtabs

import private/[helpers, types]


type
  Builder = object
    idMap: TableRef[string, Widget]
    widgets: seq[Widget]

  BuilderRef = ref Builder

proc newBuilder*(): BuilderRef =
  new result
  result.idMap = newTable[string, Widget]()
  result.widgets = @[]



proc build(builder: BuilderRef, node: XmlNode): Widget =
  if node.tag != "object":
    raise newException(IOError, "input node is not an object")

  var widget = initUiWidget()

  for child in node.items():
    case child.tag
    of "property":
      widget.props[child.attr("name")] = child.innerText
    of "child":
      for n in child.items:
        if n.tag == "object":
          var c = builder.build(n)
          addChild(result, c)
    else:
      discard

  echo "Building ", node.attr("class")
  case node.attr("class")
  of "GtkWindow":
    result = makeWindow(widget)
  of "GtkBox":
    result = makeBox(widget)
  else: discard

  if node.attr("id") != "":
    builder.idMap[node.attr("id")] = result


proc load*(builder: BuilderRef, path: string) =
  var root = loadXml(path)
  if root.tag != "interface":
    raise newException(IOError, "invalid glade file")

  for node in root.items:
    if node.tag == "object":
       builder.widgets.add builder.build(node)
