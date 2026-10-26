# AuraDictText

字典纯文本展示组件，包版本、导入方式、共用选项字段及全部证据见 [组件库入口](README.md)。本页行为以 `@fxft/aura-ui@1.1.2` 实现为准。

## Props

以下属性均可选。**Text 不提供 `emptyText`，应使用 `fallback`；不支持数组 value，也不提供 labelKey/valueKey。**

| Prop | 声明类型 | 默认值 / 作用 |
| --- | --- | --- |
| `options` | `Array<AuraDictOption \| AuraDictValue>` | `[]`，调用方字典选项 |
| `value` | `AuraDictValue` | `undefined`，单个展示值 |
| `fallback` | `string` | `''`，无匹配项时取 `fallback \|\| 原始值文本`；空字符串不能强制隐藏非空原始值 |
| `size` | `string \| number` | `undefined`，字号，number 转 px |
| `type` | `'primary' \| 'success' \| 'info' \| 'warning' \| 'danger'` | `undefined`，选项类型无效/缺失时回退该类型 |
| `color` | `string` | `''`，选项无有效颜色时回退该颜色 |
| `ellipsis` | `boolean` | `false`；为 true 时设置 truncated、line-clamp=1 及 title 文本 |
| `maxWidth` | `string \| number` | `undefined`，最大宽度，number 转 px |
| `tag` | `string` | `'span'`，传给 ElText 的渲染标签 |

### 匹配、空值和展示

- 对象取 `option.value`，原始选项取自身，排除 null/undefined 选项值后按 `String` 匹配，使用 **options 中第一个匹配项**。与 Tag 不同，不回退以 label 取值。
- 输入 null/undefined 在运行时转为空字符串参与匹配，因此可能匹配 `value: ''` 的选项；未匹配时显示 `fallback || ''`。正常非空未匹配值默认显示原始编码；业务若需要友好兜底，应显式传入真实 i18n fallback。
- 对象展示 `option.label || String(option.value ?? '')`，空字符串 label 会回退 value；原始选项直接展示自身。选项 elTagType 的有效语义类型优先于组件 type；选项 color 优先于组件 color，选项 elTagClass 追加为类名。

## 默认行为与业务配置边界

组件默认行为仅是公开契约事实，不意味着业务必须自行增加兜底。fallback 或未知值展示按真实需求配置；未经要求不新增转换、硬编码或覆盖值，不用自设 fallback 掩盖字典类型、选项来源或编码匹配错误。说明当前用途时写具体业务语义，不把组件默认行为描述成业务额外实现。

## Slots、Events 与 Methods

| 公开项 | 契约 |
| --- | --- |
| 自定义 Slots | 未提供 |
| 自定义 Events | 未提供 |
| 暴露函数 / 实例方法 | 未提供；没有 getLabel、refresh 或远程加载方法 |
| v-model 更新契约 | 未提供，只读展示 |

“未提供”依据组件声明及产物中的自定义 emits/expose/插槽实现，不将 Vue 通用属性或 ElText 内部能力当作组件公开 API。证据路径与指纹在 [组件库入口](README.md) 维护，不重复复制。
