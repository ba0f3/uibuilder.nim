import ui, strutils, strtabs, types

proc initUiWidget*(): UiWidget =
  result.props = newStringTable(modeCaseInsensitive)
  result.children = @[]

proc makeWindow*(w: UiWidget): Window
proc makeBox*(w: UiWidget): Box

template makeChild*(p: Widget, w: UiWidget) =
  when p is Window:
    p.setChild makeWindow(w)
  when p is Box:
    p.add makeBox(w)

template addChild*(p, c: Widget) =
  when p is Window:
    p.setChild c
  elif p is Box:
    p.add c
  else:
    raise newException(KeyError, "not supported yet")


proc makeWindow(w: UiWidget): Window =
  var result: Window
  var
    title = ""
    width = 640
    height = 480

  if w.props.hasKey("name"):
    title = w.props["name"]

  if w.props.hasKey("default_width"):
    width = parseInt(w.props["default_width"])

  if w.props.hasKey("default_height"):
    height = parseInt(w.props["default_height"])

  result = newWindow(title, width, height, false)
  if w.children.len > 0:
    makeChild(result, w.children[0])


proc makeBox(w: UiWidget): Box =
  var
    padded = false

  if w.props.hasKey("orientation") and w.props["orientation"] != "vertical":
    result = newHorizontalBox(padded)
  else:
    result = newVerticalBox(padded)

  if w.children != nil:
    for child in w.children:
      makeChild(result, child)
