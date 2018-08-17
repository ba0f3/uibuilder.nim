import macros, tables, strtabs, strformat, xml, xml/selector
import builder, types, helpers


proc makeMenu(stmtList: NimNode, node: XmlNode) {.compileTime.} =
  for m in node.select("> child > object.GtkMenuItem"):
    var props = m.getProperties()

    var
      menuName = props.getOrDefault("id", "")
      menuLabel = props.getOrDefault("label", "")

    if menuName.len == 0:
      menuName = genIdStatic("menu")
    stmtList.add(newVarStmt(ident(menuName), newCall(ident("newMenu"), newStrLitNode(menuLabel))))

    if props.getOrDefault("visible", "True") != "True":
      stmtList.add(newCall(ident("hide"), ident(menuName)))


    for item in m.select("> child > object.GtkMenu > child > object"):
      props = item.getProperties()
      var
        menuItemName = props.getOrDefault("id", "")
        menuItemLabel = props.getOrDefault("label", "")
      if menuItemName.len == 0:
        menuItemName = genIdStatic("menuitem")
      case item.attr("class")
      of "GtkMenuItem":
        stmtList.add parseStmt(fmt"var {menuItemName} = {menuName}.addItem(""{menuItemLabel}"", proc() = discard)")
      of "GtkCheckMenuItem":
        stmtList.add parseStmt(fmt"var {menuItemName} = {menuName}.addCheckItem(""{menuItemLabel}"", proc() = discard)")

      if props.getOrDefault("visible", "True") != "True":
        stmtList.add(newCall(ident("hide"), ident(menuItemName)))


proc gen(builder: BaseBuilder, stmtList: NimNode, widget: BuilderWidget, parent: BuilderWidget, parentName = ""): string {.compileTime.} =

  if widget.kind == None:
    return

  var name = getIdStatic(widget)
  result = name

  case widget.kind
  of UiWindow:
    stmtList.add(
      newVarStmt(
        ident(name), newCall(ident("newWindow"), newStrLitNode(widget.name), newLit(widget.width), newLit(widget.height), newLit(builder.hasMenubar))
      ),
      newAssignment(
        newDotExpr(ident(name), ident("margined")), ident("true")
      )
    )
    stmtList.add parseStmt(name & ".onClosing = (proc (): bool = return true)")

    if widget.visible:
      stmtList.add(newCall(ident("show"), ident(name)))
  of UiBox:
    var procName = "newVerticalBox"
    if widget.orientation == HORIZONTAL:
      procName = "newHorizontalBox"
    stmtList.add(newVarStmt(
      ident(name), newCall(ident(procName))
    ))
  of UiGroup:
    stmtList.add(newVarStmt(
      ident(name), newCall(ident("newGroup"), newStrLitNode(widget.groupTitle), ident("true"))
    ))
  of UiButton:
    stmtList.add(newVarStmt(
      ident(name), newCall(ident("newButton"), newStrLitNode(widget.buttonText))
    ))
  of UiCheckBox:
    stmtList.add(newVarStmt(
      ident(name), newCall(ident("newCheckbox"), newStrLitNode(widget.checkboxText))
    ))
  of UIEntry:
    stmtList.add(newVarStmt(
      ident(name), newCall(ident("newEntry"), newStrLitNode(widget.entryText))
    ))
  of UILabel:
    stmtList.add(newVarStmt(
      ident(name), newCall(ident("newLabel"), newStrLitNode(widget.label))
    ))
  of UISpinbox:
    var adj: Adjustment
    if widget.adjustmentId.len > 0 and builder.adjustmentById.hasKey(widget.adjustmentId):
      adj = builder.adjustmentById[widget.adjustmentId]
      stmtList.add(newVarStmt(
        ident(name), newCall(ident("newSpinBox"), newLit(adj.lower), newLit(adj.upper))
      ))
      stmtList.add(newAssignment(
        newDotExpr(ident(name), ident("value")), newLit(adj.value)
      ))
  of UiProgressBar:
    stmtList.add(newVarStmt(
      ident(name), newCall(ident("newProgressBar"))
    ))
  of UICombobox:
    stmtList.add(newVarStmt(
      ident(name), newCall(ident("newCombobox"))
    ))
  of UIEditableCombobox:
    stmtList.add(newVarStmt(
      ident(name), newCall(ident("newEditableCombobox"))
    ))
    for item in widget.items:
      stmtList.add(newCall(ident("add"), ident(name), newStrLitNode(item)))
  of UISeparator:
    stmtList.add(newVarStmt(
      ident(name), newCall(ident("newHorizontalSeparator"))
    ))
  of UISlider:
    var adj: Adjustment
    if widget.sliderAdjustmentId.len > 0 and builder.adjustmentById.hasKey(widget.sliderAdjustmentId):
      adj = builder.adjustmentById[widget.sliderAdjustmentId]
      stmtList.add(newVarStmt(
        ident(name), newCall(ident("newSlider"), newLit(adj.lower), newLit(adj.upper))
      ))
      stmtList.add(newAssignment(
        newDotExpr(ident(name), ident("value")), newLit(adj.value)
      ))
  of UIRadioButtons:
    stmtList.add(newVarStmt(
      ident(name), newCall(ident("newRadioButtons"))
    ))
    for button in widget.buttons:
      stmtList.add(newCall(ident("add"), ident(name), newStrLitNode(button)))
  of UiTab:
    stmtList.add(newVarStmt(
      ident(name), newCall(ident("newTab"))
    ))
    for i in 0..<widget.labels.len:
      let panelName = builder.gen(stmtList, widget.children[i], widget, name)
      stmtList.add(
        newCall(ident("add"), ident(name), newStrLitNode(widget.labels[i]), ident(panelName))
      )
  of UiMultilineEntry:
    var procName = "newNonWrappingMultilineEntry"
    if widget.wrapText:
      procName = "newMultilineEntry"

    stmtList.add(newVarStmt(
      ident(name), newCall(ident(procName))
    ))
    stmtList.add(newAssignment(
        newDotExpr(ident(name), ident("text")), newStrLitNode(widget.text))
    )
  else:
    discard

  if not widget.visible:
    stmtList.add(newCall(ident("hide"), ident(name)))

  if parent.kind != None and parentName.len != 0:
    case parent.kind
    of UIWindow:
      stmtList.add(newCall(ident("setChild"), ident(parentName), ident(name)))
    of UIBox:
      if widget.kind == UIBox:
        stmtList.add(newCall(ident("add"), ident(parentName), ident(name), ident("true")))
      else:
        stmtList.add(newCall(ident("add"), ident(parentName), ident(name), ident("false")))
    of UIGroup:
      stmtList.add(newAssignment(
        newDotExpr(ident(parentName), ident("child")), ident(name)
      ))
    else:
      discard
  if widget.kind != UiTab:
    for child in widget.children:
      discard builder.gen(stmtList, child, widget, name)

macro build*(path: static[string]): typed =
  result = newStmtList()
  var glade = staticRead(path)
  var root = parseXml(glade)

  if root.name != "interface":
    raise newException(IOError, "invalid glade file")

  var builder = newBaseBuilder()

  if not root.children.isNil:
    for child in root.children:
      if child.name == "object" and child.attr("class") == "GtkMenuBar":
        builder.hasMenuBar = true
        makeMenu(result, child)

    for child in root.children:
      if child.name == "object" and child.attr("class") != "GtkMenuBar":
        var
          widget: BuilderWidget
        builder.parseXml(child, widget)
        discard builder.gen(result, widget, widget)


