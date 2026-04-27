module = "bionicreading"

sourcefiledir = "."
unpackdir = "build/unpacked"

checkengines = {"luatex"}
typesetexe = "lualatex"

unpackfiles = {"bionicreading.ins"}
sourcefiles = {"bionicreading.dtx", "bionicreading.ins"}
installfiles = {"*.sty", "*.lua"}
typesetfiles = {"bionicreading-en.tex", "bionicreading-cn.tex"}
docfiles = {
  "README.md",
  "README.zh-CN.md",
  "LICENSE",
  "example.tex",
}
