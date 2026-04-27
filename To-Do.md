# To-Do

## 可配置强调字体

当前实现默认把被强调的西文 glyph 从普通字体 ID 替换为 `\bfseries` 对应的字体 ID。控制点在 `bionicreading.dtx` 中的 `\__bionicreading_lua_register_font_pair:`，抽取后对应 `bionicreading.sty`。

后续可以考虑新增一个字体强调选项，例如：

```tex
\bionicsetup{emphasis-command=\itshape}
\bionic[emphasis-command=\bfseries\itshape]{inline text}
```

设计要点：

- 该选项只应控制字体系列/形状类命令，例如 `\bfseries`、`\itshape`、`\bfseries\itshape`。
- 不建议支持 `\Large`、`\small` 这类字号命令，因为局部放大词首 glyph 会改变行高、字距和断行稳定性。
- 该机制仍然属于 LuaTeX node 后端的 font id 替换，不恢复 TeX 字符串扫描路径。
- 默认值保持 `\bfseries`。
- 文档中应明确这是“目标字体选择”，不是对文本包裹任意 TeX 命令。

实现 To-Do：

1. 在 `bionicreading.dtx` 的 LaTeX3 keys 中新增 `emphasis-command`。
2. 用 token list 保存强调字体命令，默认 `\bfseries`。
3. 在 `\__bionicreading_lua_register_font_pair:` 中用该 token list 替换硬编码的 `\bfseries`。
4. 从 `.dtx` 抽取 `bionicreading.sty`。
5. 更新英文文档和 `test.tex`。
6. 验证 `\bionic[emphasis-command=\itshape]{...}` 和 `bionicpar` 中的字体形状替换。

## 可选颜色机制

颜色处理不能通过当前 font id 替换直接完成。当前 Lua 后端只做：

```lua
glyph.font = bold_font
```

这适合 `\bfseries`、`\itshape` 一类字体替换，但不适合 `\color{cyan}`。颜色需要额外的 LuaTeX 节点机制，例如插入 PDF color push/pop 节点，或使用 LuaTeX/LaTeX color attribute。

建议接口：

```tex
\bionicsetup{color=none}
\bionic[color=cyan]{inline text}
\begin{bionicpar}[color=red]
...
\end{bionicpar}
```

设计要点：

- 默认值应为 `color=none`，表示不额外设置颜色，保留外层文档当前颜色。
- 不建议默认强制黑色，因为这会覆盖用户已有的颜色环境。
- 颜色机制应与字体强调机制独立：字体仍负责粗体/斜体等，颜色单独负责 PDF 绘制颜色。
- CJK 和数学公式当前不被强调，因此颜色也不应作用到这些内容。
- 如果用户外层已有 `\color{...}`，内部 bionic color 应在强调片段结束后恢复原颜色，不能污染后文。

推荐实现路线：

1. 依赖 `xcolor` 解析用户颜色名。
2. TeX 侧把颜色名转换成 RGB 三元组。
3. Lua 侧维护颜色表，例如 `color_map[id] = { r, g, b }`。
4. 使用额外 LuaTeX attribute 存储 color id，或把 fixation/color 信息组合进统一 marker。
5. Lua 回调中只对已经被选为强调前缀的 glyph 应用颜色。
6. 不要给每个 glyph 单独插入 push/pop，应按连续 emphasized glyph run 包一层颜色。
7. 颜色结束后必须 pop/reset，避免影响后续文本。

实现 To-Do：

1. 在 `bionicreading.dtx` 的 keys 中新增 `color`，默认 `none`。
2. 引入 `xcolor` 或确认 LaTeX3 color 接口是否足够。
3. 设计 TeX 到 Lua 的颜色注册函数，例如 `bionicreading.register_color(id, r, g, b)`。
4. 给 `\bionic`、`\bionicstart`、`bionicpar` 设置颜色 attribute。
5. 修改 Lua `bold_word`，在确定强调 glyph 后同时记录颜色 run。
6. 在 Lua node list 中插入颜色 push/pop 节点。
7. 更新 `.dtx` 文档，说明颜色只影响被强调前缀。
8. 更新 `test.tex`，覆盖 `color=cyan`、`color=red`、外层颜色嵌套、CJK/math 跳过。
9. 使用 `lualatex -halt-on-error` 编译 `test.tex`、`mwe.tex`、`bionicreading.dtx`。
