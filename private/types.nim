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

  BuilderWidget* = object
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
      value*: int
      min*: int
      max*: int
    else:
      discard

