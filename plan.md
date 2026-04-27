# 西文仿生阅读实现调研计划与源码笔记

## 目标

当前目标是只针对西文实现一种可控的“仿生阅读”效果。在正式设计本项目算法前，先参考已有开源仓库的实现方式，尤其关注以下问题：

- 文本如何切分成可处理的“词”
- 哪些字符被视为单词的一部分
- 每个词前部到底加粗多少字符
- 是否支持词长分级、参数化 `fixation`、透明度或更复杂的排版控制
- 是否处理 HTML、标点、断词、PDF glyph 等复杂输入

本次已将相关仓库克隆到 [materials](E:\Desktop\binoic-reading\materials) 目录下，并阅读其核心源码。

## 本次参考仓库

### 1. `Gumball12/text-vide`

- 仓库: `https://github.com/Gumball12/text-vide`
- 本地路径: [materials/text-vide](E:\Desktop\binoic-reading\materials\text-vide)
- 关键文件:
  - [packages/text-vide/src/index.ts](E:\Desktop\binoic-reading\materials\text-vide\packages\text-vide\src\index.ts)
  - [packages/text-vide/src/getFixationLength.ts](E:\Desktop\binoic-reading\materials\text-vide\packages\text-vide\src\getFixationLength.ts)
  - [HOW.md](E:\Desktop\binoic-reading\materials\text-vide\HOW.md)

### 2. `Poucous/smartReader`

- 仓库: `https://github.com/Poucous/smartReader`
- 本地路径: [materials/smartReader](E:\Desktop\binoic-reading\materials\smartReader)
- 关键文件:
  - [Chrome/content_scripts/modifyHtml.js](E:\Desktop\binoic-reading\materials\smartReader\Chrome\content_scripts\modifyHtml.js)
  - [README.md](E:\Desktop\binoic-reading\materials\smartReader\README.md)

### 3. `Cveinnt/bionify`

- 仓库: `https://github.com/Cveinnt/bionify`
- 本地路径: [materials/bionify](E:\Desktop\binoic-reading\materials\bionify)
- 关键文件:
  - [src/utils.js](E:\Desktop\binoic-reading\materials\bionify\src\utils.js)
  - [README.md](E:\Desktop\binoic-reading\materials\bionify\README.md)

### 4. `NisooJadhav/BionicReader`

- 仓库: `https://github.com/NisooJadhav/BionicReader`
- 本地路径: [materials/BionicReader](E:\Desktop\binoic-reading\materials\BionicReader)
- 关键文件:
  - [app.js](E:\Desktop\binoic-reading\materials\BionicReader\app.js)
  - [README.md](E:\Desktop\binoic-reading\materials\BionicReader\README.md)

### 5. `windingwind/bionic-for-zotero`

- 仓库: `https://github.com/windingwind/bionic-for-zotero`
- 本地路径: [materials/bionic-for-zotero](E:\Desktop\binoic-reading\materials\bionic-for-zotero)
- 关键文件:
  - [src/reader/pdf.ts](E:\Desktop\binoic-reading\materials\bionic-for-zotero\src\reader\pdf.ts)
  - [src/utils/font.ts](E:\Desktop\binoic-reading\materials\bionic-for-zotero\src\utils\font.ts)

### 6. `yitong2333/Bionic-Reading`

- 仓库: `https://github.com/yitong2333/Bionic-Reading`
- 本地路径: [materials/Bionic-Reading-userscript](E:\Desktop\binoic-reading\materials\Bionic-Reading-userscript)
- 关键文件:
  - [仿生阅读(Bionic Reading)-1.6.user.js](E:\Desktop\binoic-reading\materials\Bionic-Reading-userscript\仿生阅读(Bionic Reading)-1.6.user.js)
  - [README.md](E:\Desktop\binoic-reading\materials\Bionic-Reading-userscript\README.md)

### 补充参考. `dhruv2x/Read-Faster-Chrome-Extension`

- 仓库: `https://github.com/dhruv2x/Read-Faster-Chrome-Extension`
- 本地路径: [materials/Read-Faster-Chrome-Extension](E:\Desktop\binoic-reading\materials\Read-Faster-Chrome-Extension)
- 关键文件:
  - [content_scripts/modifyHtml.js](E:\Desktop\binoic-reading\materials\Read-Faster-Chrome-Extension\content_scripts\modifyHtml.js)
  - [README.md](E:\Desktop\binoic-reading\materials\Read-Faster-Chrome-Extension\README.md)
- 备注: 其核心实现与 `smartReader` 极度相似，基本可视为同一类字符扫描算法的另一份实现。

## 各仓库的具体实现总结

## 1. `text-vide`: 最系统化、最接近“可配置 fixation”的实现

这是本次调研里最值得重点参考的仓库。它不是简单地“前半部分加粗”，而是做了比较完整的词识别和 `fixationPoint` 分级。

### 核心做法

- 用正则 `(\p{L}|\p{Nd})*\p{L}(\p{L}|\p{Nd})*` 找出可转换词
- 也就是说：词中可以有字母和数字，但必须至少包含一个字母
- 可以跳过 HTML tag 和 HTML entity
- 对每个匹配词，计算其应加粗的前缀长度
- 用可配置的分隔符包装加粗段，默认是 `<b>...</b>`

### 具体加粗逻辑

它的关键不在简单比例，而在 [getFixationLength.ts](E:\Desktop\binoic-reading\materials\text-vide\packages\text-vide\src\getFixationLength.ts) 里的 `FIXATION_BOUNDARY_LIST`。

实现方式是：

- 预定义 5 套边界表，对应不同 `fixationPoint`
- 给定一个词长，查它落在哪个边界区间
- 由“距边界末尾的位置”反推出要加粗多少字符
- `fixationPoint` 越高，通常加粗越少，视觉节奏越轻

这意味着它是：

- 按词长离散映射
- 不是固定百分比
- 也不是简单 “长度小于 4 加粗 1 个，否则一半”

### 工程特点

- 支持多语言，只要该语言以空格分词
- 能规避 HTML 标签和实体误处理
- 特别处理了连字符、数字、特殊字符
- `HOW.md` 明确说明它是参考官方 API 行为做的近似实现

### 评价

如果本项目想做“接近官方公开思路”的西文版本，这个仓库是最重要的参考之一。它已经把“词长分档 + fixation 参数化”的思路落成代码。

## 2. `smartReader`: 基于字符扫描的“固定前两个字母加粗”

`smartReader` 的实现风格和 `text-vide` 完全不同。它不是先分词再处理，而是直接扫描 DOM 文本节点中的字符。

### 核心做法

- 遍历目标元素的 `childNodes`
- 只处理 `nodeType === 3` 的文本节点
- 对每个文本节点逐字符扫描
- 在判断“当前是一个词的起始位置”时，直接创建 `<b>` 节点插入 DOM

### 具体加粗逻辑

在 [modifyHtml.js](E:\Desktop\binoic-reading\materials\smartReader\Chrome\content_scripts\modifyHtml.js) 中：

- 只有当当前字符、后一个字符、后两个字符都被视为字母时，才会触发起始加粗逻辑
- 一旦触发，就把当前字符和下一个字符一起包进 `<b>`
- 然后 `k++`，直接跳过第二个字符
- 遇到非字母字符时，重置计数器，视为下一个词的起点

可以把它概括为：

- 词首固定加粗 2 个字符
- 词长不足 3 时，通常不会进入这条规则
- 不做按词长比例变化
- 词边界主要靠“非字母字符”来判断

### 工程特点

- 直接改写 DOM
- 不依赖复杂词法规则
- 简单、快，但较粗糙
- 对标点、缩写、短词、混合字符的处理不精细

### 评价

这是一个适合快速原型的实现，但离“官方 fixation 分级”较远。它更像一种非常朴素的视觉提示算法。

## 3. `bionify`: 可配置规则串驱动的实现

`bionify` 的最大特点是：它把加粗逻辑抽象成一串可配置参数，而不是写死在代码里。

### 核心做法

在 [src/utils.js](E:\Desktop\binoic-reading\materials\bionify\src\utils.js) 中，默认算法字符串是：

`- 0 1 1 2 0.4`

它被解析为：

- 第一位 `-` 或 `+` 表示是否跳过部分常见短词
- 中间若干数字表示不同短词长度对应的固定加粗字符数
- 最后一位小数表示长词的加粗比例

### 具体加粗逻辑

默认规则含义大致是：

- 长度 1 的词，加粗 0 个字符
- 长度 2 的词，加粗 1 个字符
- 长度 3 的词，加粗 1 个字符
- 长度 4 的词，加粗 2 个字符
- 长度 >= 5 的词，加粗 `ceil(length * 0.4)`

此外还有一个“常见词跳过”逻辑：

- 若启用 `exclude`
- 且词长 `<= 3`
- 且词在 `commonWords` 列表中
- 那么直接原样返回，不加粗

### 工程特点

- 文本按空格 `split(" ")` 切词
- 用自定义标签 `<bionify>` 包装加粗段和非加粗段
- 样式通过 `.bionify-highlight` 和 `.bionify-rest` 注入
- 非重点部分默认降低透明度

### 局限

- 仅靠空格切词，标点和缩写处理较弱
- DOM 替换比较激进
- 短词排除逻辑和常见词表是经验性的，不是语言学规则

### 评价

这是一个非常适合做“可调参数版西文仿生阅读”的参考。它把“固定映射 + 比例规则 + 常见词排除”组合在一起，足够实用。

## 4. `BionicReader`: 最简单的“前半部分加粗”

这是最朴素的实现，适合作为最小可行版本的下限参考。

### 核心做法

在 [app.js](E:\Desktop\binoic-reading\materials\BionicReader\app.js) 中：

- 用 `split(/\s+/)` 按空白切词
- 对每个词取 `Math.round(word.length / 2)` 作为分界
- 前半部分包进 `<strong>`
- 后半部分保持普通文本

### 具体加粗逻辑

规则可以直接概括为：

- 所有词统一加粗前 50% 左右字符
- 没有短词特判
- 没有标点特判
- 没有词长分级
- 没有透明度或对比度控制

### 评价

这是最容易实现的版本，但也最远离官方公开的 `Fixation` 思路。它可以用来验证 UI 和读感，但不适合直接作为正式算法。

## 5. `bionic-for-zotero`: PDF glyph 级重绘，处理最复杂

这是本次调研里工程复杂度最高的实现。它不是改 HTML，而是直接 patch PDF.js 的 `showText` 渲染路径，对 glyph 流重新分组和重绘。

### 核心做法

在 [src/reader/pdf.ts](E:\Desktop\binoic-reading\materials\bionic-for-zotero\src\reader\pdf.ts) 中：

- patch PDF.js 的 `showText`
- 把一串 glyph 识别成词
- 计算每个词需要加粗的前缀长度
- 将 glyph 分成“bold 段”和“light 段”
- 用不同 font weight 和 opacity 分段重绘

### 词识别逻辑

它定义了：

- `CONVERTIBLE_REGEX`: 词中必须至少有一个字母，可混入数字
- `SEPARATOR_REGEX`: 标点、符号、空白都视为分隔符

也就是说：

- 先按 glyph 逐个扫描
- 遇到 separator 就结束一个词
- 只对满足“至少含字母”的词做加粗处理

### 具体加粗逻辑

其规则比前几个仓库都更细：

- 默认 `boldNumber = 1`
- 若词长 `< 4`，加粗 1 个字符
- 否则加粗 `ceil(wordLength / 2)`
- 如果这个值大于 6，会寻找靠近该位置的最近非元音字符，把断点尽量落在非元音后面
- 最后再叠加一个 `parsingOffset`，允许用户手动微调

它还专门处理 PDF 中常见的断词问题：

- 若词尾带零宽占位符，可能意味着单词被跨行打断
- 此时会把前半段整个加粗
- 下一段续词则可能跳过加粗，以避免重复强调

### 视觉层面的额外处理

这个仓库不只处理“加粗多少”，还处理：

- `opacityContrast`
- `weightContrast`
- `weightOffset`

也就是说它不仅改变词首字重，还能降低剩余部分透明度，或拉开明暗对比。

### 评价

这是最接近“完整阅读模式”的实现之一。对于纯网页正文来说，它的 PDF 补丁部分不必照搬，但它的词边界、长词截断、非元音对齐和对比度控制都很值得借鉴。

## 6. `Bionic-Reading` 用户脚本: 规则直白，加入了句首和常见词特判

这个脚本的设计思路比 `BionicReader` 更实用一些，因为它在词长规则之外还加入了句首词和常见功能词的特殊处理。

### 核心做法

在 [仿生阅读(Bionic Reading)-1.6.user.js](E:\Desktop\binoic-reading\materials\Bionic-Reading-userscript\仿生阅读(Bionic Reading)-1.6.user.js) 中：

- 先按句号加空白切句
- 再按空白切词
- 对每个词调用 `formatWord`
- 用 `<b>` 包裹需要强调的前缀

### 具体加粗逻辑

规则是：

- 如果是句首单词，只加粗第一个字母
- 如果是 `prepositions` 列表中的常见词，也只加粗第一个字母
- 否则：
  - 长度 `<= 2`，加粗 1 个字符
  - 长度 `<= 5`，加粗 2 个字符
  - 长度 `>= 6`，加粗最多 4 个字符

### 值得注意的细节

- 仓库里定义了 `suffixes`，但当前这版脚本实际上没有使用它
- 这说明作者有词形层面的扩展想法，但还没有真正落到实现中
- 禁用方式是直接 `location.reload()`，因此它更像一次性页面改写脚本，而不是可逆 DOM 变换

### 评价

这是一个非常适合“经验规则版西文仿生阅读”的参考。它没有复杂表格，也没有 PDF patch，但它体现了一个重要思路：不是所有词都应该按同一条公式处理。

## 7. `Read-Faster-Chrome-Extension`: 与 `smartReader` 同类

这个仓库的 [content_scripts/modifyHtml.js](E:\Desktop\binoic-reading\materials\Read-Faster-Chrome-Extension\content_scripts\modifyHtml.js) 与 `smartReader` 的核心逻辑几乎一致：

- 字符级扫描文本节点
- 以“连续三个字母起头”为条件
- 词首固定加粗两个字符
- 遇到非字母重置

README 里写了更理想化的规则：

- 1 字母词不加粗
- 2 和 3 字母词加粗 1 个
- 4 字母词加粗 2 个
- 5+ 字母词加粗 40%

但当前代码并没有实现这套更丰富的规则，而仍是偏简单的“前两个字符加粗”版本。这一点说明：

- 仓库的 README 叙述和实际代码并不完全一致

这个现象值得记录，避免后续调研时只看文档不看源码。

## 横向比较

### A. 最简单的实现

- `BionicReader`

特点：

- 按空白切词
- 统一前半部分加粗

优点：

- 非常容易实现

缺点：

- 太粗糙，几乎没有词长策略

### B. 固定前缀实现

- `smartReader`
- `Read-Faster-Chrome-Extension`

特点：

- 字符扫描
- 词首固定加粗 2 个字符

优点：

- 不需要复杂词长表

缺点：

- 对短词和标点处理弱
- 难以贴近官方 `fixation` 分档

### C. 经验规则实现

- `bionify`
- `Bionic-Reading` 用户脚本

特点：

- 按词长分级
- 短词、常见词可能跳过或减弱
- 一部分实现提供透明度控制

优点：

- 实用，容易调参

缺点：

- 规则带较强经验性

### D. 接近“官方化”的实现

- `text-vide`
- `bionic-for-zotero`

特点：

- 不只是“前半部分加粗”
- 有明确的词长映射或更复杂的断点策略
- 对 HTML / glyph / opacity / weight 有更完善处理

优点：

- 更适合作为正式算法参考

缺点：

- 实现复杂度更高

## 对本项目的直接启发

如果本项目当前只针对西文，我建议优先考虑以下两条路线之一。

### 路线 A: `text-vide` 风格

规则：

- 以 Unicode 字母和数字匹配词
- 词必须至少包含一个字母
- 支持跳过 HTML tag / entity
- 用“词长边界表”来决定加粗长度
- 保留一个 `fixationPoint` 参数

优点：

- 最接近官方公开的“按词长分类 + fixation 可调”思路
- 可扩展性好

### 路线 B: `bionify` 风格

规则：

- 短词使用固定表
- 长词使用比例
- 可选跳过常见功能词
- 可选降低非重点部分透明度

优点：

- 易于调参
- 更容易做成前端可配置功能

## 当前结论

综合本次源码调研，最有价值的结论是：

1. “仿生阅读”并没有单一开源标准算法。
2. 开源实现大致分为三类：固定前缀、按词长经验规则、近似官方的 fixation 映射。
3. 如果要做一个更严谨的西文实现，应优先参考 `text-vide` 和 `bionic-for-zotero`，而不是直接采用“前半部分加粗”的最简方案。
4. 如果要做一个实现成本较低、同时仍有一定可调性的版本，则 `bionify` 提供了很好的参数化思路。

## 下一步建议

下一步可以直接在本项目里产出一版“西文仿生阅读规则草案”，建议内容包括：

- 输入文本的 token 识别规则
- 标点与连字符处理规则
- 词长到加粗长度的映射表
- 是否跳过常见功能词
- 是否提供 `fixationPoint` 参数
- 是否提供 `opacity` 作为第二层视觉强化

这会比继续泛泛讨论概念更接近可编码实现。

## LaTeX 宏包实现 To-do List

当前新的目标是编写一个 LaTeX 宏包，用 LaTeX3 实现只针对西文的仿生阅读效果。基础例子见 [mwe.tex](E:\Desktop\binoic-reading\mwe.tex)，但最终实现不应只做固定百分比加粗，而应优先移植 `text-vide` 的 `fixationPoint` 边界表方案。`text-vide` 的具体规则已整理到 [text-vide-notes.md](E:\Desktop\binoic-reading\text-vide-notes.md)。

### 1. 调研与规则固化

- [x] 阅读 `mwe.tex`，确认当前最小示例是“按百分比切分每个空格分隔词”
- [x] 阅读 `text-vide` 的 `index.ts`、`getFixationLength.ts`、`README.md`、`HOW.md`
- [x] 新建 `text-vide-notes.md`，整理参数、匹配规则和加粗长度计算
- [x] 根据 LaTeX 可实现性，确认当前实现只处理 ASCII 西文字符 `A-Z / a-z / 0-9`
- [x] 明确对带重音拉丁字母的处理策略：暂不处理，后续可通过选项扩展
- [x] 明确对连字符词的处理：按 `text-vide` 思路拆成两个词

### 2. 宏包接口设计

- [x] 新建宏包文件 `bionicreading.sty`，包名不使用连字符
- [x] 使用 `expl3` 和 `xparse` 风格接口
- [x] 提供全局设置命令，例如：

```tex
\bionicsetup{
  fixation-point = 1,
  enabled = true
}
```

- [x] 提供局部处理命令，例如：

```tex
\bionic{Confucius said: Madam, I'm Adam.}
```

- [x] 提供段落环境，例如：

```tex
\begin{bionicpar}
Confucius said: Madam, I'm Adam.
\end{bionicpar}
```

- [x] 提供环境选项，例如：

```tex
\begin{bionicpar}[fixation-point=3]
...
\end{bionicpar}
```

### 3. LaTeX3 key-value 参数

- [x] 使用 `l3keys` 定义模块键 `bionicreading`
- [x] 实现 `fixation-point`，取值范围 `1..5`
- [x] 实现 `enabled`，允许全局开关
- [x] 实现 `bold-command` 样式 hook，默认使用 `\textbf`
- [x] 当前实现固定为 ASCII-only 行为
- [x] 当前实现固定为 hyphen split 行为

### 4. 移植 `text-vide` fixation 计算

- [x] 在 LaTeX3 中存储 5 组 `FIXATION_BOUNDARY_LIST`
- [x] 实现 `\__bionicreading_get_fixation_length:nN` 内部函数
- [x] 输入为词长和 `fixation-point`
- [x] 输出为加粗字符数
- [x] 逻辑等价于 `text-vide`：

```text
fixationLengthFromLast = first index where wordLength <= boundary
if found:
  boldLength = wordLength - fixationLengthFromLast
else:
  boldLength = wordLength - boundaryList.length
boldLength = max(boldLength, 0)
```

- [x] 为 `fixation-point=1` 验证关键样例：`text -> tex+t`，`bionic -> bion+ic`，`reading -> readi+ng`
- [x] 为 `fixation-point=5` 验证关键样例：`text-vide -> t+ext-v+ide`

### 5. 文本扫描与 token 识别

- [x] 当前实现以普通文本参数为输入，不处理任意复杂 TeX token 流
- [x] 使用 LaTeX3 字符串扫描输入
- [x] 识别 ASCII 字母和数字组成的候选 token
- [x] token 中必须至少包含一个 ASCII 字母才处理
- [x] 纯数字原样输出
- [x] CJK 字符原样输出，不参与词长计算，不被加粗
- [x] 标点、空白、连字符原样输出，并作为 token 分隔符
- [x] 撇号词如 `I'm` 按 apostrophe 拆分为 `I` 和 `m`

### 6. 数学模式保护

- [x] 明确当前支持范围：正文中出现 `$...$` 时不处理内部内容
- [x] 实现 `$...$` 的跳过机制
- [ ] 评估 `\(...\)` 和 `\[...\]` 在 token 扫描中的可靠处理方式
- [ ] 对常见数学环境不在环境内部做自动解析，或明确限制
- [ ] 在文档中声明：复杂数学环境建议放在仿生阅读环境外，或作为后续增强项

### 7. CJK 保护

- [x] 确保非 ASCII 字符默认原样输出
- [x] 不对中文、日文、韩文字符调用加粗
- [ ] 混排文本中只处理 ASCII 西文 token，例如：

```tex
这是 a simple test 文本。
```

预期只处理 `a`、`simple`、`test`。

### 8. 环境实现策略

- [x] 环境要求内容作为普通段落文本，不支持任意复杂嵌套命令
- [x] 使用环境收集正文后统一处理
- [x] 使用 `+b` 参数收集环境 body
- [x] 环境内部处理时保持局部设置，不污染全局参数
- [x] 环境结束时正常输出处理后的段落

### 9. 测试文件

- [x] 将 [mwe.tex](E:\Desktop\binoic-reading\mwe.tex) 改成加载新宏包的测试文件
- [ ] 新增一个更完整的测试文件，例如 `test.tex`
- [x] 测试普通英文句子
- [x] 测试 `fixation-point=1` 和 `fixation-point=5`
- [x] 测试英文和 CJK 混排
- [x] 测试纯数字、字母数字混合
- [x] 测试标点和连字符
- [x] 测试 `$a+b=c$` 不被处理

### 10. 编译验证

- [x] 确认本机可用 LaTeX 引擎
- [x] 使用 `latexmk` 编译测试文件
- [x] 涉及 CJK 测试，使用 XeLaTeX
- [ ] 若只测试 ASCII 英文，可先用 pdfLaTeX
- [x] 检查编译日志中的错误、警告和 overfull box

### 11. 文档

- [ ] 在 `notes.md` 或独立 README 中补充宏包使用说明
- [ ] 说明本宏包采用 `text-vide` 风格 fixation 边界表
- [ ] 说明当前实现仅处理 ASCII 西文
- [ ] 说明 CJK 与数学公式默认不加粗
- [ ] 说明与官方 Bionic Reading 和 `text-vide` 的差异

## 实现优先级建议

第一阶段先完成：

- `text-vide` 边界表移植
- `\bionicsetup`
- `\bionic{...}`
- `bionicpar` 环境
- ASCII 西文 token 扫描
- CJK 原样输出
- `$...$` 原样输出

第二阶段再考虑：

- `\(...\)`、`\[...\]` 数学保护
- 撇号词更精细处理
- 带重音拉丁字母支持
- 样式 hook
- 更完整的宏包文档和测试矩阵
