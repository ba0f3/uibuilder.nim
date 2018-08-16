import strutils, tables, strtabs, xml, xml/selector
import helpers, types

const CHILDREN_SELECTOR = "> child > object"

type
  BaseBuilder* = ref object of RootObj
    adjustmentById*: TableRef[string, Adjustment]
    textBufferById*: StringTableRef
    hasMenuBar*: bool

proc newBuilder*(): BaseBuilder =
  new result
  result.adjustmentById = newTable[string, Adjustment]()
  result.textBufferById = newStringTable()
  result.hasMenuBar = false


proc parseXml*(builder: BaseBuilder, node: XmlNode, parent: var BuilderWidget, level = 0) =
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

  if props.hasKey("visbile"):
    widget.visible = props["visible"] == "True"
  else:
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
  of "GtkTextBuffer":
    builder.textBufferById[widget.id] = props.getOrDefault("text", "")
    return
  else:
    discard

  #echo " ".repeat(level*2), node.attr("class"), " ", widget.kind

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
  of UiSlider:
    if props.hasKey("adjustment"):
      widget.sliderAdjustmentId = props["adjustment"]
  of UiEditableCombobox:
    widget.items = @[]
    for item in node.select("item"):
      widget.items.add(item.text)
  of UiRadioButtons:
    widget.buttons = @[]
    children = node.select("> child > object.GtkRadioButton")
  of UiTab:
    var nextIsLabel = false
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
  of UiMultilineEntry:
    if props.hasKey("buffer"):
      widget.text = builder.textBufferById[props["buffer"]]
    if props.hasKey("wrap_mode"):
      widget.wrapText = true
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
