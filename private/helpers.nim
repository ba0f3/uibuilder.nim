import ui, strutils, strtabs, types, xmltree, q, random

randomize()

proc getProperties*(node: XmlNode): StringTableRef =
  result = newStringTable(modeCaseInsensitive)
  for prop in node.select("> property"):
    result[prop.attr("name")] = prop.innerText

proc getLabel*(node: XmlNode): string =
  for prop in node.select("> property"):
    if prop.attr("name") == "label":
      result = prop.innerText

proc getLabel*(node: seq[XmlNode]): string {.inline.} =
  if not node.isNil and node.len > 0:
    result = getLabel(node[0])

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

proc toWidgetKind*(GTKClass: string): WidgetKind =
  case GTKClass
  of "GtkWindow":
    result = UiWindow
  of "GtkFrame":
    result = UiGroup
  of "GtkBox":
    result = UiBox
  of "GtkButton":
    result = UiButton
  of "GtkCheckButton":
    result = UiCheckbox
  of "GtkEntry":
    result = UiEntry
  of "GtkLabel":
    result = UiLabel
  of "GtkNotebook":
    result = UiTab
  of "GtkSpinButton":
    result = UiSpinBox
  of "GtkScale":
    result = UiSlider
  of "GtkProgressBar":
    result = UiProgressBar
  of "GtkSeparator":
    result = UiSeparator
  of "GtkComboBox":
    result = UiCombobox
  of "GtkComboBoxText":
    result = UiEditableCombobox
  of "GtkMenu":
    result = UiMenu
  of "GtkMenuItem":
    result = UiMenuItem
  of "GtkTextView":
    result = UiMultilineEntry
  else:
    result = None
    {.warning: "not supported widget"}

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


proc initUiWidget*(kind: WidgetKind, node: XmlNode): BuilderWidget =
  result.kind = kind
  result.children = @[]
  result.node = node

proc getId*(w: BuilderWidget, ids: var seq[string] = @[]): string =
  if w.id.len > 0:
    result = w.id
    ids.add(result)
  else:
    var kindStr = $w.kind
    if w.kind == None:
      return ""
    var prefix = kindStr[2..<kindStr.len]
    prefix[0] = prefix[0].toLowerAscii()
    result = prefix & toHex(rand(high(int))).toLowerAscii()

