import ui, strutils, strtabs, types, xmltree, q


proc getProperties*(node: XmlNode): StringTableRef =
  result = newStringTable(modeCaseInsensitive)
  for prop in node.select("> property"):
    result[prop.attr("name")] = prop.innerText


proc addChild*[ParentWidget: Widget, ChildWidget: Widget](p: var ParentWidget, c: ChildWidget) =
  if p of Window:
    ((Window)p).setChild(c)
  elif p of Box:
    ((Box)p).add(c)
  elif p of Group:
    ((Group)p).child = c
  else:
    #if c of Window:
    #  p = c
    discard


proc makeWindow*(hasMenuBar: bool, props: StringTableRef): Window =
  var
    width = 640
    height = 480

  if props.hasKey("default_width"):
    width = parseInt(props["default_width"])

  if props.hasKey("default_height"):
    height = parseInt(props["default_height"])

  result = newWindow(props.getOrDefault("name", "Window"), width, height, hasMenuBar)
  result.margined = true
  result.onClosing = (proc (): bool = return true)
  show(result)

proc makeBox*(props: StringTableRef): Box =
  var
    padded = false
  if props.hasKey("orientation") and props["orientation"] != "vertical":
    result = newHorizontalBox(padded)
  else:
    result = newVerticalBox(padded)

proc makeGroup*(props: StringTableRef): Group =
  newGroup("Basic Controls", true)
