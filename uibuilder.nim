import ui, os, streams, xmlparser, xmltree, strutils, tables, strtabs, q
import private/[helpers, types]

type
  Builder = ref object of RootObj
    ids: TableRef[string, Widget]
    hasMenuBar: bool


proc newBuilder*(): Builder =
  new result
  result.ids = newTable[string, Widget]()
  result.hasMenuBar = false

proc parseXml(builder: Builder, node: XmlNode, parent: var BuilderWidget, level = 0) =
  ## This helper will process and simplifies the glade xml, remove unsupported objects
  var
    props = node.getProperties()
    children: seq[XmlNode]
  var
    kind = node.attr("class").toWidgetKind
    widget = initUiWidget(kind, node)
  echo " ".repeat(level*2), node.attr("class"), " ", kind
  case kind
  of UiWindow:
    if props.hasKey("default_width"):
      widget.width = parseInt(props["default_width"])
    if props.hasKey("default_height"):
      widget.height = parseInt(props["default_height"])
    widget.name = props.getOrDefault("name", "")
  of UiGroup:
    # find group title
    var labels = node.select("> child > object.GtkLabel")
    if labels.len > 0:
      for prop in labels[0].select("> property"):
        if prop.attr("name") == "label":
          widget.groupTitle = prop.innerText
    # ignore GtkAlignment
    children = node.select("> child > object.GtkAlignment > child > object")
  of UiBox:
    if props.hasKey("orientation") and props["orientation"] == "vertical":
      widget.orientation = VERTICAL
  of UiButton:
    widget.buttonText = props.getOrDefault("label", "")
  of UiCheckbox:
    widget.checkboxText = props.getOrDefault("label", "")
  of UiEntry:
    widget.entryText = props.getOrDefault("text", "")
  of UiLabel:
    widget.label = props.getOrDefault("label", "")
  of UiSpinBox:
    if props.hasKey("value"):
      widget.value = parseInt(props.getOrDefault("value", "0"))
  else:
    discard

  # process children
  if children.isNil:
    children = node.select("> child > object")

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
    # default window
    parent = (Window)widget
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
    widget = newSpinbox(0, 100)
    ((SpinBox)widget).value = ui.value
    parent.addChild((SpinBox)widget)
  of UiProgressBar:
    widget = newProgressBar()
    parent.addChild((ProgressBar)widget)
  of UICombobox:
    widget = newCombobox()
    parent.addChild((Combobox)widget)
  of UIEditableCombobox:
    widget = newEditableCombobox()
    parent.addChild((EditableCombobox)widget)

  else:
    discard

  for child in ui.children:
    builder.build(child, widget)

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
  mainLoop()
