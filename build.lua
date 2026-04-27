module = "bionic-reading"

sourcefiledir = "."
unpackdir = "build/unpacked"

checkengines = {"luatex"}
typesetexe = "lualatex"

unpackfiles = {"bionic-reading.ins"}
sourcefiles = {"bionic-reading.dtx", "bionic-reading.ins"}
installfiles = {"*.sty", "*.lua"}
typesetfiles = {"bionic-reading-en.tex", "bionic-reading-cn.tex"}
docfiles = {
  "README.md",
  "README.zh-CN.md",
  "LICENSE",
  "example.tex",
}
