import ui, strutils, strtabs

proc makeWindow*(props: StringTableRef, children: seq[Widget]): Window =
  var
    title = ""
    width = 640
    height = 480

  if props.hasKey("name"):
    title = props["name"]

  if props.hasKey("default_width"):
    width = parseInt(props["default_width"])

  if props.hasKey("default_height"):
    height = parseInt(props["default_height"])


  result = newWindow(title, width, height, true)
  if children.len > 0:
    result.setChild((Box)children[0])
