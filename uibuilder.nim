import ui, os, streams, strutils, tables, strtabs, strformat, os, xml, xml/selector
import uibuilderpkg/[builder, helpers, uihelpers, types, uitypes]

type
  Builder* = ref object of BaseBuilder
    widgetById: TableRef[string, Widget]


proc newBuilder*(): Builder =
  new result
  result.widgetById = newTable[string, Widget]()
  result.adjustmentById = newTable[string, Adjustment]()
  result.textBufferById = newStringTable()
  result.hasMenuBar = false

proc getWidgetById*(builder: Builder, id: string): Widget =
  if builder.widgetById.hasKey(id):
    result = builder.widgetById[id]
  else:
    raise newException(ValueError, "no widget with id " & id & " found")

proc run*(builder: Builder) =
  mainLoop()


proc build(builder: Builder, ui: BuilderWidget, parent: var Widget) =
  var widget: Widget
  case ui.kind
  of UiWindow:
    widget = makeWindow(ui, builder.hasMenuBar)
  of UiBox:
    widget = makeBox(ui)
    parent.addChild((Box)widget)
  of UiGroup:
    widget = newGroup(ui.groupTitle, true)
    parent.addChild((Group)widget)
  of UiButton:
    widget = newButton(ui.buttonText)
    parent.addChild((Button)widget)
  of UICheckbox:
    widget = newCheckbox(ui.checkboxText)
    parent.addChild((Checkbox)widget)
  of UIEntry:
    widget = newEntry(ui.entryText)
    parent.addChild((Entry)widget)
  of UILabel:
    widget = newLabel(ui.label)
    parent.addChild((Label)widget)
  of UISpinbox:
    var adj: Adjustment
    if ui.adjustmentId.len > 0 and builder.adjustmentById.hasKey(ui.adjustmentId):
      adj = builder.adjustmentById[ui.adjustmentId]
    var spinbox = newSpinbox(adj.lower, adj.upper)
    if ui.value != 0:
      spinbox.value = ui.value
    else:
      spinbox.value = adj.value
    parent.addChild(spinbox)
    widget = spinbox
  of UiProgressBar:
    widget = newProgressBar()
    ((ProgressBar)widget).value = 50
    parent.addChild((ProgressBar)widget)
  of UICombobox:
    widget = newCombobox()
    parent.addChild((Combobox)widget)
  of UIEditableCombobox:
    var ec = newEditableCombobox()
    for item in ui.items:
      ec.add(item)
    parent.addChild(ec)
    widget = ec
  of UISeparator:
    widget = newHorizontalSeparator()
    parent.addChild((Separator)widget)
  of UISlider:
    var adj: Adjustment
    if ui.sliderAdjustmentId.len > 0 and builder.adjustmentById.hasKey(ui.sliderAdjustmentId):
      adj = builder.adjustmentById[ui.sliderAdjustmentId]
    widget = newSlider(adj.lower, adj.upper)
    ((Slider)widget).value = adj.value
    parent.addChild((Slider)widget)
  of UIRadioButtons:
    widget = newRadioButtons()
    for button in ui.buttons:
      ((RadioButtons)widget).add(button)
    parent.addChild((RadioButtons)widget)
  of UiTab:
    var tab = newTab()
    for i in 0..<ui.labels.len:
      var panel: Widget
      builder.build(ui.children[i], panel)
      if panel of Box:
        tab.add(ui.labels[i], (Box)panel)
      else:
        raise newException(ValueError, "Tab " & ui.labels[i] & "'s panel must be a box")
    parent.addChild(tab)
    if ui.id.len > 0:
      builder.widgetById[ui.id] = tab
    # don't add children directly like other container
    return
  of UiMultilineEntry:
    if ui.wrapText:
      widget = newMultilineEntry()
    else:
      widget = newNonWrappingMultilineEntry()
    ((MultilineEntry)widget).text = ui.text
    parent.addChild((MultilineEntry)widget)
  else:
    discard

  for child in ui.children:
    builder.build(child, widget)

  if parent.isNil:
    parent = widget

  if ui.id.len > 0:
    builder.widgetById[ui.id] = widget

proc makeMenu(menuBar: XmlNode) =
  var
    menu: Menu
    menuItem: MenuItem

  for m in menuBar.select("> child > object.GtkMenuItem"):
    var properties = m.getProperties()

    menu = newMenu(properties.getOrDefault("label", ""))
    if properties.getOrDefault("visible", "True") != "True":
      menu.hide()

    for item in m.select("> child > object.GtkMenu > child > object"):
      properties = item.getProperties()
      case item.attr("class")
      of "GtkMenuItem":
        menuItem = menu.addItem(properties.getOrDefault("label", ""), proc() = discard)
      of "GtkCheckMenuItem":
        menuItem = menu.addCheckItem(properties.getOrDefault("label", ""), proc() = discard)
      else:
        {.warning: "only GtkMenuItem and GtkCheckMenuItem is supported".}

      if properties.getOrDefault("visible", "True") != "True":
        menuItem.hide()
      # what is the property for disabled menu item??
      #if properties.getOrDefault("can_focus", "True") != "True":
      #   menuItem.disable()

proc load*(builder: Builder, path: string) =
  init()
  var root = parseXml(readFile(path))
  if root.name != "interface":
    raise newException(IOError, "invalid glade file")

  # search for GtkMenuBar and init it first
  if not root.children.isNil:
    for node in root.children:
        if node.name == "object" and node.attr("class") == "GtkMenuBar":
          builder.hasMenuBar = true
          makeMenu(node)

  if not root.children.isNil:
    for node in root.children:
      if node.name == "object" and node.attr("class") != "GtkMenuBar":
        var
          rootBuilderWidget: BuilderWidget
          rootWidget: Widget

        builder.parseXml(node, rootBuilderWidget)
        builder.build(rootBuilderWidget, rootWidget)

proc gen*(builder: Builder, f: File, ui: BuilderWidget, ids: var seq[string], parent: BuilderWidget, parentName = ""): string {.discardable.} =
  if ui.kind == None:
    return

  var name = getId(ui, ids)
  result = name

  case ui.kind
  of UiWindow:
    f.write &"""var {name} = newWindow("{ui.name}", {ui.width}, {ui.height}, {builder.hasMenuBar})
{name}.margined = true
{name}.onClosing = (proc (): bool = return true)
{name}.show()
"""
  of UiBox:
    if ui.orientation == HORIZONTAL:
      f.write &"var {name} = newHorizontalBox()\n"
    else:
      f.write &"var {name} = newVerticalBox()\n"
  of UiGroup:
    f.write &"var {name} = newGroup(\"{ui.groupTitle}\", true)\n"
  of UiButton:
    f.write &"var {name} = newButton(\"{ui.buttonText}\")\n"
  of UICheckbox:
    f.write &"var {name} = newCheckbox(\"{ui.checkboxText}\")\n"
  of UIEntry:
    f.write &"var {name} = newEntry(\"{ui.entryText}\")\n"
  of UILabel:
    f.write &"var {name} = newLabel(\"{ui.label}\")\n"
  of UISpinbox:
    var adj: Adjustment
    if ui.adjustmentId.len > 0 and builder.adjustmentById.hasKey(ui.adjustmentId):
      adj = builder.adjustmentById[ui.adjustmentId]
      f.write &"""var {name} = newSpinBox({adj.lower}, {adj.upper})
{name}.value = {adj.value}
"""
  of UiProgressBar:
    f.write &"var {name} = newProgressBar()\n"
  of UICombobox:
    f.write &"var {name} = newCombobox()\n"
  of UIEditableCombobox:
    f.write &"var {name} = newEditableCombobox()\n"
    for item in ui.items:
      f.write &"{name}.add(\"{item}\")\n"
  of UISeparator:
    f.write &"var {name} = newHorizontalSeparator()\n"
  of UISlider:
    var adj: Adjustment
    if ui.sliderAdjustmentId.len > 0 and builder.adjustmentById.hasKey(ui.sliderAdjustmentId):
      adj = builder.adjustmentById[ui.sliderAdjustmentId]
      f.write &"""var {name} = newSlider({adj.lower}, {adj.upper})
{name}.value = {adj.value}
"""
  of UIRadioButtons:
    f.write &"var {name} = newRadioButtons()\n"
    for button in ui.buttons:
      f.write &"{name}.add(\"{button}\")\n"
  of UiTab:
    f.write &"var {name} = newTab()\n"
    for i in 0..<ui.labels.len:
      var panelName = builder.gen(f, ui.children[i], ids, ui, name)
      f.write &"{name}.add(\"{ui.labels[i]}\", {panelName})\n"
    return
  of UiMultilineEntry:
    if ui.wrapText:
      f.write &"var {name} = newMultilineEntry()\n"
    else:
      f.write &"var {name} = newNonWrappingMultilineEntry()\n"
    f.write &"{name}.text = \"\"\"{ui.text}\"\"\"\n"
  else:
    discard

  if not ui.visible:
    f.write &"{name}.hide()\n"

  if parent.kind != None and parentName.len != 0:
    f.write genAddStmt(parent.kind, parentName, ui.kind, name)
    f.write "\n"

  for child in ui.children:
    builder.gen(f, child, ids, ui, name)

proc codegen*(builder: Builder, path: string) =
  var root = parseXml(readFile(path))
  if root.name != "interface":
    raise newException(IOError, "invalid glade file")
  var
    lastDot = path.rfind('.')
    outputPath = path
  outputPath[lastDot..<path.len] = ".nim"

  var output = open(outputPath, fmWrite)
  output.write """import ui
when isMainModule:
  init()
"""

  var ids: seq[string] = @[]
  if not root.children.isNil:
    for node in root.children:
      if node.name == "object":
        var rootBuilderWidget: BuilderWidget

        builder.parseXml(node, rootBuilderWidget)
        builder.gen(output, rootBuilderWidget, ids, rootBuilderWidget)

  if ids.len > 0:
    output.write "\nexport " & ids.join(", ")

    output.write """


when isMainModule:
  mainLoop()
"""

  output.close()
  echo &"""Nim code saved at: {outputPath}
Run command bellow to see the result:

# nim c -r {outputPath}
"""

when isMainModule:
  if paramCount() != 1:
    quit(&"Usage: {paramStr(0)} <glade file>")
  var path = paramStr(1)
  if not path.fileExists:
    quit("Glade file {path} not found")
  var b = newBuilder()
  b.codegen(path)

