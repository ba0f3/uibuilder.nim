import ui, strtabs

type
  WidgetKind* = enum
    UIButton,
    UIWindow,
    UIBox,
    UICheckbox,
    UIEntry,
    UILabel,
    UITab,
    UIGroup,
    UISpinbox,
    UISlider,
    UIProgressBar,
    UISeparator,
    UICombobox,
    UIEditableCombobox,
    UIRadioButtons,
    UIMultilineEntry,
    UIMenuItem,
    UIMenu

  UiWidget* = object
    kind*: WidgetKind
    id*: string
    props*: StringTableRef
    children*: seq[UiWidget]
