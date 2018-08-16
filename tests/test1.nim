import ui, ospaths, uibuilderpkg/codegen


init()
const path = joinPath(staticExec("pwd"), "test.glade")
build(path)
mainLoop()