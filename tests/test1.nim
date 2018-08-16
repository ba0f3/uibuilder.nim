import ui, ospaths, uibuilderpkg/codegen

proc main() =
  const path = joinPath(staticExec("pwd"), "test.glade")
  build(path)

init()
main()
mainLoop()