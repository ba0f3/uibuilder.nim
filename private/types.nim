import ui, strtabs


type
  WidgetKind* = enum
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

  UiWidget* = ref object of RootObj
    kind*: WidgetKind
    props*: StringTableRef
    widget*: Widget
    children*: seq[UiWidget]
