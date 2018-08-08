import ui, os, streams, xmlparser, xmltree, strutils, tables, strtabs, q
import private/[helpers, types]

const CHILDREN_SELECTOR = "> child > object"

type
  Builder = ref object of RootObj
    widgetById: TableRef[string, Widget]
    adjustmentById: TableRef[string, Adjustment]
    hasMenuBar: bool


proc newBuilder*(): Builder =
  new result
  result.widgetById = newTable[string, Widget]()
  result.adjustmentById = newTable[string, Adjustment]()
  result.hasMenuBar = false

proc getWidgetById*(builder: Builder, id: string): Widget =
  if builder.widgetById.hasKey(id):
    result = builder.widgetById[id]
  else:
    raise newException(ValueError, "no widget with id " & id & " found")

proc run*(builder: Builder) =
  mainLoop()

proc parseXml(builder: Builder, node: XmlNode, parent: var BuilderWidget, level = 0) =
  ## This helper will process and simplifies the glade xml, remove unsupported objects
  var
    props = node.getProperties()
    children: seq[XmlNode]
    gtkClass = node.attr("class")
    kind = gtkClass.toWidgetKind

  # Hack for radio buttons group
  if gtkClass == "GtkBox":
    var class = node.select("> style > class")
    if class.len > 0 and class[0].attr("name") == "radiobuttons":
      kind = UiRadioButtons

  var widget = initUiWidget(kind, node)

  if node.attr("id").len > 0:
    widget.id = node.attr("id")

  if props.hasKey("visbile") and props["visible"] == "True":
    widget.visible = true

  case gtkClass
  of "GtkAdjustment":
      var adj: Adjustment
      if props.hasKey("lower"):
        adj.lower = parseInt(props["lower"])
      if props.hasKey("upper"):
        adj.upper = parseInt(props["upper"])
      if props.hasKey("value"):
        adj.value = parseInt(props["value"])

      builder.adjustmentById[widget.id] = adj
      return
  else:
    discard

  echo " ".repeat(level*2), node.attr("class"), " ", widget.kind

  case widget.kind
  of UiWindow:
    if props.hasKey("default_width"):
      widget.width = parseInt(props["default_width"])
    if props.hasKey("default_height"):
      widget.height = parseInt(props["default_height"])
    widget.name = props.getOrDefault("name", "")

    children = node.select(CHILDREN_SELECTOR)
  of UiGroup:
    # find group title
    widget.groupTitle = getLabel(node.select("> child > object.GtkLabel"))
    # ignore GtkAlignment
    children = node.select("> child > object.GtkAlignment > child > object")
  of UiBox:
    if props.hasKey("orientation") and props["orientation"] == "vertical":
      widget.orientation = VERTICAL
    children = node.select(CHILDREN_SELECTOR)
  of UiButton:
    widget.buttonText = props.getOrDefault("label", "")
  of UiCheckbox:
    widget.checkboxText = props.getOrDefault("label", "")
  of UiEntry:
    widget.entryText = props.getOrDefault("text", "")
  of UiLabel:
    widget.label = props.getOrDefault("label", "")
  of UiSpinBox:
    if props.hasKey("adjustment"):
       widget.adjustmentId = props["adjustment"]
    if props.hasKey("value"):
      widget.value = parseInt(props["value"])
  of UiEditableCombobox:
    widget.items = @[]
    for item in node.select("item"):
      widget.items.add(item.innerText)
  of UiRadioButtons:
    widget.buttons = @[]
    children = node.select("> child > object.GtkRadioButton")
  of UiTab:
    var
      nextIsLabel = false
    widget.labels = @[]
    for child in node.select("> child"):
      if child.attr("type") == "tab":
        if not nextIsLabel:
          raise newException(ValueError, "got a label but a widget expected")
        nextIsLabel = false
        widget.labels.add getLabel(child.select("> object.GtkLabel"))
      else:
        if nextIsLabel:
          raise newException(ValueError, "invalid tab child widget, a label expected")
        nextIsLabel = true
        children.add(child.select("> object"))

  else:
    if gtkClass == "GtkRadioButton":
      case parent.kind
      of UIRadioButtons:
        parent.buttons.add(props.getOrDefault("label", "radiobutton"))
      else:
        discard

  # process children
  if not children.isNil:
    for child in children:
      builder.parseXml(child, widget, level+1)

  # link with its parent
  if parent.kind == None:
    parent = widget
  else:
    parent.children.add(widget)


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
    widget = newSlider(0, 100)
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
  var root = loadXml(path)
  if root.tag != "interface":
    raise newException(IOError, "invalid glade file")

  # search for GtkMenuBar and init it first
  for node in root.items:
    if node.tag == "object" and node.attr("class") == "GtkMenuBar":
      builder.hasMenuBar = true
      makeMenu(node)

  for node in root.items:
    if node.tag == "object" and node.attr("class") != "GtkMenuBar":
      var
        rootBuilderWidget: BuilderWidget
        rootWidget: Widget

      builder.parseXml(node, rootBuilderWidget)
      builder.build(rootBuilderWidget, rootWidget)
