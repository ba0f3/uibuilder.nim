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

proc getId*(kind: WidgetKind): string =
  var prefix =
    case kind:
    of UiWindow:
      "win"
    of UiGroup:
      "group"
    of UiBox:
      "box"
    of UiButton:
      "btn"
    of UiCheckbox:
      "cbox"
    of UiEntry:
      "entry"
    of UiLabel:
      "label"
    of UiTab:
      "tab"
    of UiSpinBox:
      "spinbox"
    of UiSlider:
      "slider"
    of UiProgressBar:
      "pbar"
    of UiSeparator:
      "sepa"
    of UiCombobox:
      "cbox"
    of UiEditableCombobox:
      "ec"
    of UiMenu:
      "mnu"
    of UiMenuItem:
      "mitem"
    of UiMultilineEntry:
      "me"
    else:
      ""
  if prefix.len == 0:
    return prefix
  result = prefix & "_" & toHex(rand(high(int))).toLowerAscii()