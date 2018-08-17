# uibuilder.nim
UI Builder for [@nim-lang/ui](https://github.com/nim-lang/ui) using [Glade](https://glade.gnome.org/)

Checkout [examples](https://github.com/ba0f3/uibuilder.nim/tree/master/examples)

### Usage
> you must have [Glade](https://glade.gnome.org/) installed in order to build UI and create *.glade files

```shell
$ nimble install uibuilder
```

UIBuilder contains a library for load glade file and construct UI on-the-fly, another part - `uibuilder` binary - which generates a Nim module from glade file.

#### Construct UI at compile-time
This method is prefered:
- Glade file compiled into AST at compile-time
- No more glade files in your distribution package
- Output module wont depends on UIBuilder
- Binary size reduced 50%


```nim
import ui, ospaths, uibuilderpkg/codegen

const path = joinPath(staticExec("pwd"), "test.glade")

init()
build(path)
mainLoop()
```

#### Load Glade on run-ime file

```nim
import ui, uibuilder

var builder = newBuilder()
builder.load("ui.glade")
builder.run()
```

#### Generate Nim module (WIP)
> the `uibuilder` command will generates a Nim module which can run standalone or importable.
> the generated module will not requires `uibuilder`, it just need `ui` module
>
> Note: only widgets have `id` are exported

```shell
$ uibuilder examples/basic_controls.glade
Nim code saved at: examples/basic_controls.nim
Run command bellow to see the result:

# nim c -r examples/basic_controls.nim
```

### Showcases:
- [Nimble GUI](https://github.com/ThomasTJdev/nim_nimble_gui)

### Widgets
> Almost widgets are same as GTK Widgets, but there are some widgets need a small hack in order to work
##### Group
UI Builder converts `GtkFrame` into a `Group`, it will finds nested `GtkLabel` and make it as `Group`'s  title
##### RadioButtons
In Glade, you must cover a group of `GtkRadioButton`s with a `GtkBox`, the box must have a style class named `radiobuttons`
##### Tab
`Tab` uses `GtkNotebook`, tab's container must be a `GtkBox`
##### MultilineEntry
Just add a `GtkTextView` widget to make a `MultilineEntry`, you also can pre-define text for it w/ `GtkTextBuffer`
##### Menu
libui requires to init `Menu` first, before creating main `Window`, so it better make a `GtkMenuBar` separated
##### Slider
 `Slider` uses `GtkScale`
You can defined ajustment for `Slider` and `SpinBox` with `GtkAdjustment`

![examples](https://raw.githubusercontent.com/ba0f3/uibuilder.nim/master/examples/basic_controls.png)

### Todos
- [ ] Better event handling
- [x] Code generator for static layout
- [ ] Support QT Designer layout file
