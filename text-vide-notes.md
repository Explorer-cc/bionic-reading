# text-vide 方案实现笔记

## 目标

本文记录 `Gumball12/text-vide` 的具体实现逻辑，作为后续编写 LaTeX 宏包时的算法参考。这里关注的是西文环境下的“仿生阅读”加粗策略，而不是 HTML 或 JavaScript 工程细节本身。

本地参考源码位于：

- [materials/text-vide/packages/text-vide/src/index.ts](E:\Desktop\binoic-reading\materials\text-vide\packages\text-vide\src\index.ts)
- [materials/text-vide/packages/text-vide/src/getFixationLength.ts](E:\Desktop\binoic-reading\materials\text-vide\packages\text-vide\src\getFixationLength.ts)
- [materials/text-vide/HOW.md](E:\Desktop\binoic-reading\materials\text-vide\HOW.md)

## API 参数

`text-vide` 的公开 API 是：

```ts
textVide(text: string, options?: Options)
```

其选项类型为：

```ts
type Options = Partial<{
  sep: string | string[];
  fixationPoint: number;
  ignoreHtmlTag: boolean;
  ignoreHtmlEntity: boolean;
}>;
```

## 参数含义

### `sep`

默认值：

```ts
['<b>', '</b>']
```

作用是指定加粗片段前后的包装符。例如：

```ts
textVide('text-vide')
// '<b>tex</b>t-<b>vid</b>e'
```

在 LaTeX 宏包中，它可以对应为：

- 默认使用 `\textbf{...}`
- 或提供一个内部 hook，让用户把强调样式改成 `\bfseries`、`\fontseries{b}\selectfont`、颜色、透明度等

### `fixationPoint`

默认值：

```ts
1
```

范围：

```ts
1..5
```

作用是控制加粗强度。数值越小，通常加粗越多；数值越大，通常加粗越少。例如 README 中给出的例子：

```ts
textVide('text-vide')
// '<b>tex</b>t-<b>vid</b>e'

textVide('text-vide', { fixationPoint: 5 })
// '<b>t</b>ext-<b>v</b>ide'
```

对于 LaTeX 宏包，`fixationPoint` 应当作为最重要的全局参数暴露。

### `ignoreHtmlTag`

默认值：

```ts
true
```

作用是在处理 HTML 字符串时跳过标签内容，例如避免把 `<div>` 中的 `div` 当成普通词加粗。

LaTeX 宏包不需要实现这个选项，因为输入不是 HTML。

### `ignoreHtmlEntity`

默认值：

```ts
true
```

作用是在处理 HTML 字符串时跳过实体，例如 `&nbsp;`、`&gt;`。

LaTeX 宏包不需要实现这个选项，因为输入不是 HTML。

## 词匹配规则

`text-vide` 使用的核心正则是：

```ts
const CONVERTIBLE_REGEX = /(\p{L}|\p{Nd})*\p{L}(\p{L}|\p{Nd})*/gu;
```

含义：

- 词可以由 Unicode 字母 `\p{L}` 和 Unicode 十进制数字 `\p{Nd}` 组成
- 但词中必须至少包含一个字母
- 纯数字不会被处理
- 含字母和数字的组合会被处理

例子：

```ts
'123456'       -> 不加粗
'abc123'       -> 可加粗
'123abc'       -> 可加粗
'abc123def'    -> 可加粗
```

对本 LaTeX 宏包而言，目标明确为“只对西文字符生效”，因此可以先采用更保守的匹配范围：

```text
A-Z, a-z, 0-9
```

并要求 token 中至少有一个 ASCII 字母。这样可以自然避开 CJK 字符。后续如果需要支持带重音拉丁字母，可再扩展到 Latin-1 或 Unicode Latin ranges。

## 加粗长度计算

`text-vide` 的核心函数是 `getFixationLength(word, fixationPoint)`。

源码中定义了 5 组边界表：

```ts
const FIXATION_BOUNDARY_LIST = [
  [0, 4, 12, 17, 24, 29, 35, 42, 48],
  [1, 2, 7, 10, 13, 14, 19, 22, 25, 28, 31, 34, 37, 40, 43, 46, 49],
  [
    1, 2, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39,
    41, 43, 45, 47, 49,
  ],
  [
    0, 2, 4, 5, 6, 8, 9, 11, 14, 15, 17, 18, 20, 0, 21, 23, 24, 26, 27, 29, 30,
    32, 33, 35, 36, 38, 39, 41, 42, 44, 45, 47, 48,
  ],
  [
    0, 2, 3, 5, 6, 7, 8, 10, 11, 12, 14, 15, 17, 19, 20, 21, 23, 24, 25, 26, 28,
    29, 30, 32, 33, 34, 35, 37, 38, 39, 41, 42, 43, 44, 46, 47, 48,
  ],
];
```

算法步骤是：

1. 取当前词长 `wordLength`
2. 根据 `fixationPoint` 选择一组边界表
3. 找到第一个满足 `wordLength <= boundary` 的位置 `fixationLengthFromLast`
4. 令 `fixationLength = wordLength - fixationLengthFromLast`
5. 如果没有找到边界，则令 `fixationLength = wordLength - boundaryList.length`
6. 最后返回 `max(fixationLength, 0)`

换句话说，边界表并不直接表示“要加粗几个字符”，而是通过“当前词长落入第几个边界”换算出“末尾保留几个非加粗字符”。

## `fixationPoint=1` 的直观表

根据 `HOW.md`，`fixationPoint=1` 可以理解为下面这张表：

| 词长范围 | 末尾非加粗字符数 |     加粗字符数 |
| -------- | ---------------: | -------------: |
| 0-4      |                1 | `length - 1` |
| 5-12     |                2 | `length - 2` |
| 13-16    |                3 | `length - 3` |
| 17-24    |                4 | `length - 4` |
| 25-29    |                5 | `length - 5` |
| 30-35    |                6 | `length - 6` |
| 36-42    |                7 | `length - 7` |
| 43-48    |                8 | `length - 8` |
| 49+      |                9 | `length - 9` |

例如：

```text
text       length=4  -> bold 3 -> tex + t
bionic     length=6  -> bold 4 -> bion + ic
reading    length=7  -> bold 5 -> readi + ng
```

## `fixationPoint` 的实现解释

5 组边界表共同形成了 5 档加粗强度：

- `fixationPoint=1`: 加粗最重，通常保留较少的非加粗尾部
- `fixationPoint=5`: 加粗最轻，通常只加粗较少的词首字符

在 LaTeX 宏包中，最直接的复刻方式是完整移植这 5 组边界表，并按相同逻辑计算加粗长度。

## 特殊字符规则

根据 `HOW.md`：

- 词首和词尾的特殊字符不应被高亮
- 词内部的特殊字符在官方 API 中可能被当作普通字符
- 但 `text-vide` 自身更倾向于用特殊字符拆分 token
- 连字符 `-` 被当成空格，`text-vide` 会把 `text-vide` 处理成两个词

README 示例：

```ts
textVide('text-vide')
// '<b>tex</b>t-<b>vid</b>e'
```

对 LaTeX 宏包而言，建议采用更保守的规则：

- ASCII 字母和数字组成候选 token
- 连字符、标点、空白都作为分隔符原样输出
- 只对包含至少一个 ASCII 字母的 token 应用仿生加粗

## 数字规则

根据 `HOW.md`：

- 纯数字不加粗
- 数字和字母混合时，按普通 token 处理
- 例如 `abc123`、`123abc` 可以加粗

LaTeX 宏包可保留此规则。

## 与 LaTeX 宏包的差异

`text-vide` 处理的是普通字符串或 HTML 字符串；LaTeX 宏包处理的是 TeX token 流，因此需要额外考虑：

- 控制序列不能被拆开
- 数学模式不能被处理
- CJK 字符不能被加粗
- 分组 `{...}` 不能被错误破坏
- 段落环境需要在局部范围内启用处理
- 全局参数需要通过 LaTeX3 key-value 接口设置

因此后续实现不应试图完全照搬 JavaScript 的字符串扫描，而应移植其“词识别规则”和“加粗长度计算规则”。

## 移植特征：

- `fixationPoint`
- 5 组边界表
- token 至少包含一个 ASCII 字母才处理
- 纯数字跳过
- 连字符和标点作为分隔符
- 加粗样式默认 `\textbf`
