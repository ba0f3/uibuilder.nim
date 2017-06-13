import ui, os, streams, xmlparser, xmltree, strutils, tables, strtabs

import private/[window, box]

discard """
type
  WidgetKind = enum
    Button,
    Window,
    Box,
    Checkbox,
    Entry,
    Label,
    Tab,
    Group,
    Spinbox,
    Slider,
    ProgressBar,
    Separator,
    Combobox,
    EditableCombobox,
    RadioButtons,
    MutilineEntry,
    MenuItem,
    Menu
"""


type
  Builder = object
    idMap: TableRef[string, Widget]
    widgets: seq[Widget]

  BuilderRef = ref Builder

proc newBuilder*(): BuilderRef =
  new result
  result.idMap = newTable[string, Widget]()
  result.widgets = @[]


proc build(node: XmlNode): Widget =
  if node.tag != "object":
    raise newException(IOError, "input node is not an object")

  var
    id = node.attr("id")
    props = newStringTable(modeCaseInsensitive)
    children: seq[Widget] = @[]

  for child in node.items():
    case child.tag
    of "property":
      props[child.attr("name")] = child.innerText
    of "child":
      for n in child.items:
        if n.tag == "object":
          children.add build(n)
    else:
      discard

  case node.attr("class")
  of "GtkWindow":
    result = makeWindow(props, children)
  of "GtkBox":
    result = makeBox(props, children)


proc load*(builder: BuilderRef, path: string) =
  var root = loadXml(path)
  if root.tag != "interface":
    raise newException(IOError, "invalid glade file")

  for node in root.items:
    if node.tag == "object":
       builder.widgets.add build(node)
