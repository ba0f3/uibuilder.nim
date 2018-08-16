import strutils, strtabs, types, random, strformat, xml, xml/selector

randomize()

proc getProperties*(node: XmlNode): StringTableRef =
  result = newStringTable(modeCaseInsensitive)
  for prop in node.select("> property"):
    result[prop.attr("name")] = prop.text

proc getLabel*(node: XmlNode): string =
  for prop in node.select("> property"):
    if prop.attr("name") == "label":
      result = prop.text

proc getLabel*(node: seq[XmlNode]): string {.inline.} =
  if not node.isNil and node.len > 0:
    result = getLabel(node[0])

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


proc genAddStmt*(parentKind: WidgetKind, parentName: string, childKind: WidgetKind, childName: string): string =
  case parentKind
  of UIWindow:
    result = fmt"{parentName}.setChild({childName})"
  of UIBox:
    if childKind == UIBox:
      result = fmt"{parentName}.add({childName}, true)"
    else:
      result = fmt"{parentName}.add({childName}, false)"
  of UIGroup:
    result = fmt"{parentName}.child = {childName}"
  else:
    discard
