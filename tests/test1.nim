import ospaths, uibuilderpkg/codegen

#const glade = slurp(joinPath(staticExec("pwd"), "test.glade"))
const path = joinPath(staticExec("pwd"), "test.glade")

build(path)
