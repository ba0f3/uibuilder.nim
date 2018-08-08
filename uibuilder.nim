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
    widget: BuilderWidget
  echo " ".repeat(level*2), node.attr("class"), " ", kind
  case kind
  of None:
    {.warning: "check please".}
  of UiGroup:
    # find group title
    var labels = node.select("> child > object.GtkLabel")
    if labels.len > 0:
      for prop in labels[0].select("> property"):
        if prop.attr("name") == "label":
          props["title"] = prop.innerText

    widget = initUiWidget(UIGroup, props)
    # ignore GtkAlignment
    children = node.select("> child > object.GtkAlignment > child > object")
  else:
    widget = initUiWidget(kind, props)

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
    widget = makeWindow(builder.hasMenuBar, ui.props)
    # default window
    parent = (Window)widget
  of UiBox:
    widget = makeBox(ui.props)
    parent.addChild((Box)widget)
  of UiGroup:
    widget = newGroup(ui.props.getOrDefault("title"), true)
    parent.addChild((Group)widget)
  of UiButton:
    widget = newButton(ui.props.getOrDefault("label", "button"))
    parent.addChild((Button)widget)
  of UICheckbox:
    widget = newCheckbox(ui.props.getOrDefault("label", "checkbox"))
    parent.addChild((Checkbox)widget)
  of UIEntry:
    widget = newEntry(ui.props.getOrDefault("text", "entry"))
    parent.addChild((Entry)widget)
  of UILabel:
    widget = newLabel(ui.props.getOrDefault("label", "label"))
    parent.addChild((Label)widget)
  of UISpinbox:
    let value = parseInt(ui.props.getOrDefault("value", "0"))
    widget = newSpinbox(0, 100)
    ((SpinBox)widget).value = value
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
