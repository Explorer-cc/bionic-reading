# bionic-reading

[简体中文说明](README.zh-CN.md)

`bionic-reading` is a LuaLaTeX package that applies bionic-reading-style highlighting to western ASCII words. It bolds the leading part of each matched word while leaving CJK text and math content unchanged.

## Features

- Highlights the leading part of ASCII western words.
- Provides an inline command for short text.
- Provides a paragraph environment for longer text blocks.
- Supports global setup with `enabled` and `fixation-point` options.
- Uses LuaTeX node processing instead of string rewriting.

## Scope

- Targets western ASCII words only.
- Does not segment or transform CJK text.
- Does not modify math lists.
- Requires `LuaLaTeX`.

## Installation

This repository already includes the package source:

- `bionic-reading.sty`
- `bionic-reading.lua`

For local testing, keep these files beside your `.tex` document, or install them into your local TeX tree.

## Basic Usage

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

## Options

- `enabled=true|false`: enable or disable the effect.
- `fixation-point=1..5`: control how much of each word is highlighted.

In general, larger `fixation-point` values produce shorter highlighted prefixes.

## Public Interface

- `\bionic[<options>]{<text>}`
- `\bionicsetup{<options>}`
- `\begin{bionicpar}[<options>] ... \end{bionicpar}`
- `\bionicstart[<options>] ... \bionicstop`

## Repository Files

- `example.tex`: minimal usage example.
- `bionic-reading.dtx`: documented source.
- `bionic-reading-en.tex`: English package documentation driver.
- `bionic-reading-cn.tex`: Chinese package documentation driver.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
