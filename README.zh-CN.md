# bionic-reading

[English README](README.md)

`bionic-reading` 是一个基于 LuaLaTeX 的宏包，用来为西文 ASCII 单词添加 bionic reading 风格的前导加粗效果。它只处理匹配到的西文单词，不会改写 CJK 文本和数学公式内容。

## 功能

- 强调西文 ASCII 单词的前导部分。
- 提供适合短文本的行内命令。
- 提供适合长文本的段落环境。
- 支持通过 `enabled` 和 `fixation-point` 进行全局配置。
- 通过 LuaTeX 节点处理完成转换，而不是直接改写字符串。

## 适用范围

- 只处理西文 ASCII 单词。
- 不对 CJK 文本进行分词或转换。
- 不修改数学公式列表。
- 必须使用 `LuaLaTeX` 编译。

## 安装

仓库中已经包含宏包所需文件：

- `bionic-reading.sty`
- `bionic-reading.lua`

本地测试时，可以把这些文件放在你的 `.tex` 文档同目录下，或安装到本地 TeX 树中。

## 基本用法

```tex
\documentclass{article}
\usepackage{bionic-reading}

\begin{document}

\bionic{Bionic reading style highlighting for English text.}

\bionic[fixation-point=5]{text-vide and internationalization}

\begin{bionicpar}[fixation-point=3]
This paragraph is processed with bionic-reading-style emphasis.
\end{bionicpar}

\bionicsetup{enabled=false}
\bionic{This sentence is not transformed.}

\end{document}
```

## 选项

- `enabled=true|false`：开启或关闭效果。
- `fixation-point=1..5`：控制每个单词被强调的前缀长度。

一般来说，`fixation-point` 越大，被强调的前缀越短。

## 对外接口

- `\bionic[<options>]{<text>}`
- `\bionicsetup{<options>}`
- `\begin{bionicpar}[<options>] ... \end{bionicpar}`
- `\bionicstart[<options>] ... \bionicstop`

## 仓库文件

- `example.tex`：最小使用示例。
- `bionic-reading.dtx`：带文档的源码。
- `bionic-reading-en.tex`：英文文档驱动文件。
- `bionic-reading-cn.tex`：中文文档驱动文件。

## 许可证

本项目使用 MIT License，见 [LICENSE](LICENSE)。
