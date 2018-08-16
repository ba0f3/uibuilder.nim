import os, macros, xml
import builder, types

export newBuilder

proc gen(glade: string) {.compileTime.} =
  echo glade
  var root = parseXml(glade)
  if root.name != "interface":
    raise newException(IOError, "invalid glade file")

  var builder = newBuilder()

  if not root.children.isNil:
    for node in root.children:
      if node.name == "object" and node.attr("class") == "GtkMenuBar":
        builder.hasMenuBar = true
        #makeMenu(node)

    for node in root.children:
      if node.name == "object" and node.attr("class") != "GtkMenuBar":
        var rootBuilderWidget: BuilderWidget
        builder.parseXml(node, rootBuilderWidget)

macro a(xml: string): typed =
  gen(xml.strVal)


template build*(glade: string): typed =
  echo glade
  a(glade)
