import ui, strutils, strtabs, types, xmltree, q

proc addChild*[SomeWidget: Widget](p: SomeWidget, c: SomeWidget) =
  if p of Window:
    ((Window)p).setChild(c)
  elif p of Box:
    p.add(c)
  elif p of Group:
    p.groupSetChild(c)
  else:
    #raise newException(KeyError, "not supported yet")
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

proc makeBox*[SomeWidget: Widget](parent: var SomeWidget, props: StringTableRef) =
  var
    padded = false
    box: Box
  
  if props.hasKey("orientation") and props["orientation"] != "vertical":
    box = newHorizontalBox(padded)
  else:
    box = newVerticalBox(padded)

  parent.addChild(box)

proc makeGroup*(props: StringTableRef): Group =
  result = newGroup("Basic Controls", true)

proc getProperties*(node: XmlNode): StringTableRef =
  result = newStringTable(modeCaseInsensitive)
  for prop in node.select("> property"):
    result[prop.attr("name")] = prop.innerText
