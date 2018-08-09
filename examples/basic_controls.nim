import ui, ../uibuilder, random, posix

randomize()

var builder = newBuilder()
builder.load("basic_controls.glade")

var
  button = (Button)builder.getWidgetById("button1")
  entry = (Entry)builder.getWidgetById("entry1")
  spinbox = (SpinBox)builder.getWidgetById("spinbox1")
  slider = (Slider)builder.getWidgetById("slider1")

button.onclick = proc() =
  var mainwin = (Window)builder.getWidgetById("mainWin")
  mainwin.msgBox("Hoorray!", "Button clicked")

proc entryOnchangeHandler(e: Entry): auto =
  proc cb() =
    echo "OnChanged: ", e.text
  return cb

entry.onchanged = entryOnchangeHandler(entry)


slider.onchanged = proc (newvalue: int) =
  spinbox.value = newvalue

proc threadProc(builder: Builder) =
  var progressbar = (ProgressBar)builder.getWidgetById("progressbar1")
  while true:
    var value: int
    while value < 10:
      value = rand(100)
    progressbar.value = value
    discard sleep(1)


var th: Thread[Builder]
createThread[Builder](th, threadProc, builder)

builder.run()
