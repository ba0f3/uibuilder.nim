import ui, strtabs

type
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
    kind*: WidgetKind
    props*: StringTableRef
    children*: seq[BuilderWidget]
