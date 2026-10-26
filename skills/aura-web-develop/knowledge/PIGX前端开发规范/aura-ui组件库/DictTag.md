# AuraDictTag

字典标签展示组件，包版本、导入方式、共用选项字段及全部证据见 [组件库入口](README.md)。本页行为以 `@fxft/aura-ui@1.1.2` 实现为准。

## Props

以下属性均可选，默认值来自 1.1.2 实现；`AuraDictValue = string | number`。

| Prop | 声明类型 | 默认值 / 作用 |
| --- | --- | --- |
| `options` | `Array<AuraDictOption \| AuraDictValue>` | `[]`，调用方字典选项 |
| `value` | `AuraDictValue \| AuraDictValue[]` | `undefined`，支持单值及数组；不拆分逗号字符串 |
| `labelKey` | `string` | `'label'`，对象显示字段 |
| `valueKey` | `string` | `'value'`，对象取值字段 |
| `tagTypeKey` | `string` | `'elTagType'`，对象语义类型字段 |
| `tagClassKey` | `string` | `'elTagClass'`，对象 CSS 类字段 |
| `showIcon` | `boolean` | `false`；还需选项有 icon 且提供 icon 插槽或配置 iconComponent |
| `tagType` | `string` | `undefined`；选项有效类型优先，之后使用显式 tagType、注入配置 dictTag.tagType，最后 primary |
| `emptyText` | `string` | `''`；有选择值且完全无匹配项时才显示；没有选择值时不显示 |

### 匹配、空值和展示

- `null/undefined` 在运行时归为空选择数组（声明未将 null 纳入输入类型）；其他单值转数组，成员按 `String` 比较。`0` 和 `'0'` 相等；`''` 是可参与匹配的值，不等同于 null。数组值去重后按 **options 顺序** 筛选，重复值的选项会全部展示；部分匹配时不为未匹配成员追加 emptyText。
- 对象 label 依次取 `option[labelKey] ?? option.label ?? option.value ?? ''`；value 依次取 `option[valueKey] ?? option.value ?? option.label ?? ''`。因此空字符串 label 保留；与 Text 的逻辑或回退不同。原始字符串/数字选项自身既是标签也是取值。
- 有效类型为 `primary/success/info/warning/danger`。有 color 时采用该颜色设置文字、边框和 `${color}1A` 背景，不把任何颜色格式都宣称为合法背景色。
- 无 color、没有组件/配置 tagType，且选项类型为 `'default'`、`''` 或 `null` 时渲染普通 span；否则渲染 ElTag。缺失类型与上述显式空类型不完全相同。
- 上游说明称默认 SvgIcon，但 **1.1.2 实现没有无条件默认图标组件**；需要 icon 插槽或注入配置 iconComponent，不凭最新文档断言一定显示图标。

## Slots、Events 与 Methods

| 公开项 | 契约 |
| --- | --- |
| Slots | `icon`，参数 `{ name, color, option }`；需 showIcon=true 且选项有 icon；option 是归一化项，包含 key/label/value/tagType/tagClass/icon/color，不是原始对象 |
| 自定义 Events | 未提供 |
| 暴露函数 / 实例方法 | 未提供；没有 getLabel、refresh 或远程加载方法 |
| v-model 更新契约 | 未提供，只读展示 |

“未提供”依据组件声明及产物中的自定义 emits/expose/插槽实现，不将 Vue 通用属性或 ElTag 内部能力当作组件公开 API。证据路径与指纹在 [组件库入口](README.md) 维护，不重复复制。
