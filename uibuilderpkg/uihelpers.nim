import ui, types

proc addChild*[Parent: Widget, Child: Widget](p: Parent, c: Child) =
  if p of Window:
    ((Window)p).setChild(c)
  elif p of Box:
    if c is Box:
      ((Box)p).add(c, true)
    else:
      ((Box)p).add(c, false)
  elif p of Group:
    ((Group)p).child = c
  else:
    discard

proc makeWindow*(w: BuilderWidget, hasMenuBar: bool): Window =
  result = newWindow(w.name, w.width, w.height, hasMenuBar)
  result.margined = true
  result.onClosing = (proc (): bool = return true)
  show(result)

proc makeBox*(w: BuilderWidget): Box =
  var
    padded = true
  if w.orientation == VERTICAL:
    result = newVerticalBox(padded)
  else:
    result = newHorizontalBox(padded)

