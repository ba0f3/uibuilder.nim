import ui
when isMainModule:
  init()
var mainWin = newWindow("Control Gallery", 440, 250, false)
mainWin.margined = true
mainWin.onClosing = (proc (): bool = return true)
mainWin.show()
var box1d74f3ff6b706879 = newVerticalBox()
mainWin.setChild(box1d74f3ff6b706879)
var hbox = newHorizontalBox()
box1d74f3ff6b706879.add(hbox, true)
var group10108f180c1670ee = newGroup("Basic Controls", true)
hbox.add(group10108f180c1670ee, false)
var box28f1f2809f36fe54 = newVerticalBox()
group10108f180c1670ee.child = box28f1f2809f36fe54
var button1 = newButton("Button")
box28f1f2809f36fe54.add(button1, false)
var checkbox2319f0f4bcacbda3 = newCheckbox("Checkbox")
box28f1f2809f36fe54.add(checkbox2319f0f4bcacbda3, false)
var entry1 = newEntry("Entry")
box28f1f2809f36fe54.add(entry1, false)
var label2211571d036f8393 = newLabel("Label")
box28f1f2809f36fe54.add(label2211571d036f8393, false)
var separator0531915ee7068108 = newHorizontalSeparator()
box28f1f2809f36fe54.add(separator0531915ee7068108, false)
var multilineEntry7e893fb7a822f83c = newMultilineEntry()
box28f1f2809f36fe54.add(multilineEntry7e893fb7a822f83c, false)
var box63f6d4916f08dc42 = newVerticalBox()
hbox.add(box63f6d4916f08dc42, true)
var group6a7a52685b5a5aba = newGroup("Numbers", true)
box63f6d4916f08dc42.add(group6a7a52685b5a5aba, false)
var box5c7681b6e0eae28a = newVerticalBox()
group6a7a52685b5a5aba.child = box5c7681b6e0eae28a
var spinbox1 = newSpinBox(10, 100)
spinbox1.value = 49
box5c7681b6e0eae28a.add(spinbox1, false)
var slider1 = newSlider(10, 100)
slider1.value = 49
box5c7681b6e0eae28a.add(slider1, false)
var progressbar1 = newProgressBar()
box5c7681b6e0eae28a.add(progressbar1, false)
var group6cafa94275648e81 = newGroup("Lists", true)
box63f6d4916f08dc42.add(group6cafa94275648e81, false)
var box35a68cde4d546023 = newVerticalBox()
group6cafa94275648e81.child = box35a68cde4d546023
var combobox5528e95c98fdba47 = newCombobox()
box35a68cde4d546023.add(combobox5528e95c98fdba47, false)
var editableCombobox51a1a453bd5c2696 = newEditableCombobox()
box35a68cde4d546023.add(editableCombobox51a1a453bd5c2696, false)
var radioButtons2a80036c959d3e79 = newRadioButtons()
box35a68cde4d546023.add(radioButtons2a80036c959d3e79, false)
var tab45419c9231814f39 = newTab()
box63f6d4916f08dc42.add(tab45419c9231814f39, false)
var box0f57a413dcd0751f = newVerticalBox()

var button69b40d3c462711c1 = newButton("button")
box0f57a413dcd0751f.add(button69b40d3c462711c1, false)
var box172e7c7a6f93fb9b = newVerticalBox()

var entry3b0fffe68f8ff622 = newEntry("")
box172e7c7a6f93fb9b.add(entry3b0fffe68f8ff622, false)
var box6a62e225dc084e61 = newVerticalBox()

var label0ca5e58e8374fbcb = newLabel("label")
box6a62e225dc084e61.add(label0ca5e58e8374fbcb, false)

export mainWin, hbox, button1, entry1, spinbox1, slider1, progressbar1

when isMainModule:
      mainLoop()
