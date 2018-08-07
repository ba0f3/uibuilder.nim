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

proc simplify(builder: Builder, node: XmlNode, level = 0) =
  var
    props = node.getProperties()

  #case node.attr("class")
  #of "GtkWindow":
  #  children = node.select("child > object")
  echo " ".repeat(level*2), node.attr("class")
  var children = node.select("child > object")
  for child in children:
    builder.simplify(child, level+1)



proc build[ParentWidget: Widget](builder: Builder, node: XmlNode, parent: var ParentWidget) =
  if node.tag != "object":
    raise newException(IOError, "input node is not an object")

  var
    props = node.getProperties()
    children = node.select("child > object")

  echo "Building ", node.attr("class")
  var widget: Widget
  case node.attr("class")
  of "GtkWindow":
    widget = makeWindow(builder.hasMenuBar, props)
    parent.addChild((Window)widget)
  of "GtkBox":
    widget = makeBox(props)
    parent.addChild((Box)widget)
  of "GtkFrame":
    widget = makeGroup(props)
    parent.addChild((Group)widget)
  else: discard

  for child in children:
    builder.build(child, widget)

  if node.attr("id").len > 0:
    builder.ids[node.attr("id")] = widget

proc makeMenu(menuBar: XmlNode) =
  var
    menu: Menu
    menuItem: MenuItem

  for m in menuBar.select("> child > object.GtkMenuItem"):
    var properties = m.getProperties()

    menu = newMenu(properties.getOrDefault("label", ""))
    if properties.getOrDefault("visible", "True") != "True":
      menu.hide()

    for item in m.select("child > object.GtkMenu > child > object"):
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

  var rootWidget: Widget
  for node in root.items:
    if node.tag == "object" and node.attr("class") != "GtkMenuBar":
      builder.simplify(node)
      #builder.build(node, rootWidget)

  mainLoop()
