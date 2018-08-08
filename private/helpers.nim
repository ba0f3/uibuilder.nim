import ui, strutils, strtabs, types, xmltree, q

proc getProperties*(node: XmlNode): StringTableRef =
  result = newStringTable(modeCaseInsensitive)
  for prop in node.select("> property"):
    result[prop.attr("name")] = prop.innerText


proc addChild*[Parent: Widget, Child: Widget](p: Parent, c: Child) =
  if p of Window:
    ((Window)p).setChild(c)
  elif p of Box:
    ((Box)p).add(c, true)
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
  if props.hasKey("orientation") and props["orientation"] == "vertical":
    result = newVerticalBox(padded)
  else:
    result = newHorizontalBox(padded)


proc initUiWidget*(kind: WidgetKind, props: StringTableRef = nil): BuilderWidget =
  result.kind = kind
  result.props = props
  result.children = @[]
