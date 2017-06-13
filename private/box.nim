import ui, strutils, strtabs

proc makeBox*[SomeWidget: Widget](props: StringTableRef, children: seq[SomeWidget]): Box =
  var
    padded = false

  if props.hasKey("orientation") and props["orientation"] != "vertical":
    result = newHorizontalBox(padded)
  else:
    result = newVerticalBox(padded)

  if children != nil:
    for child in children:
      result.add(child)
