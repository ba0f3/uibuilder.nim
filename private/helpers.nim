import ui, strutils, strtabs, types, xmltree, q

proc initUiWidget*(): UiWidget =
  result.props = newStringTable(modeCaseInsensitive)
  result.children = @[]

#proc makeWindow*(w: UiWidget): Window
#proc makeBox*(w: UiWidget): Box

#template makeChild*(p: Widget, w: UiWidget) =
#  when p is Window:
#    p.setChild makeWindow(w)
#  when p is Box:
#    p.add makeBox(w)

template addChild*(p, c: Widget) =
  when p is Window:
    p.setChild(c)
  elif p is Box:
    p.add(c)
  elif p is Group:
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
  #if w.children.len > 0:
  #  makeChild(result, w.children[0])
  show(result)

proc makeBox*(w: UiWidget): Box =
  var
    padded = false

  if w.props.hasKey("orientation") and w.props["orientation"] != "vertical":
    result = newHorizontalBox(padded)
  else:
    result = newVerticalBox(padded)

  #if w.children != nil:
  #  for child in w.children:
  #    makeChild(result, child)

proc makeGroup*(w: UiWidget): Group =
  result = newGroup("Basic Controls", true)

proc getProperties*(node: XmlNode): StringTableRef =
  result = newStringTable(modeCaseInsensitive)
  for prop in node.select("> property"):
    result[prop.attr("name")] = prop.innerText
