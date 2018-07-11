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

proc build(builder: Builder, node: XmlNode, parent: var Widget) =
  if node.tag != "object":
    raise newException(IOError, "input node is not an object")

  var
    props = node.getProperties()
    children = node.select("child > object")

  echo "Building ", node.attr("class")
  case node.attr("class")
  of "GtkWindow":
    var window = makeWindow(builder.hasMenuBar, props)
    for child in children:
      window.setChild builder.build(child)
  of "GtkBox":
    makeBox(p, props)
  of "GtkFrame":
    makeGroup(props)
  else: discard

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
       builder.build(node, rootWidget)

  mainLoop()
