import ui, strtabs, xmltree

type
  Orientation* = enum
    HORIZONTAL
    VERTICAL

  WidgetKind* = enum
    None
    UIButton
    UIWindow
    UIBox
    UICheckbox
    UIEntry
    UILabel
    UITab
    UIGroup
    UISpinbox
    UISlider
    UIProgressBar
    UISeparator
    UICombobox
    UIEditableCombobox
    UIRadioButtons
    UIMultilineEntry
    UIMenuItem
    UIMenu

  Adjustment* = object
    lower*: int
    upper*: int
    value*: int

  TabPanel* = object
    label*: string
    widget*: Widget

  BuilderWidget* = object
    id*: string
    children*: seq[BuilderWidget]
    node*: XmlNode
    visible*: bool
    case kind*: WidgetKind
    of UIWindow:
      width*: int
      height*: int
      name*: string
    of UIBox:
      orientation*: Orientation
    of UIGroup:
      groupTitle*: string
    of UIButton:
      buttonText*: string
    of UIEntry:
      entryText*: string
    of UICheckbox:
      checkboxText*: string
    of UIEditableCombobox:
      items*: seq[string]
    of UiLabel:
      label*: string
    of UISpinbox:
      adjustmentId*: string
      value*: int
    of UISlider:
      sliderAdjustmentId*: string
    of UIRadioButtons:
      buttons*: seq[string]
    of UITab:
      labels*: seq[string]
    of UIMultilineEntry:
      text*: string
      wrapText*: bool
    else:
      discard

