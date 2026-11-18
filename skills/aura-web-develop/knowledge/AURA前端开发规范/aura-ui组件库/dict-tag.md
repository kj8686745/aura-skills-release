# AuraDictTag 字典标签

公共子入口 `@fxft/aura-ui/dict-tag`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

根据字典值展示标签，支持多值、图标和自定义颜色。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraDictTag from '@fxft/aura-ui/dict-tag';

const options = [{ label: '启用', value: 0, elTagType: 'success' }];
</script>

<template>
  <AuraDictTag :value="0" :options="options" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| options | 字典数据数组，每个元素可以是对象（包含 `label`、`value`、`elTagType`、`elTagClass`）或字符串、数字 | `(AuraDictOption \| string \| number)[]` | `[]` | 否 |
| value | 当前要显示的字典值，支持单值或数组 | `string \| number \| (string \| number)[]` | `undefined` | 否 |
| showIcon | 显示图标；默认使用 SDK SvgIcon，可通过插槽或应用配置覆盖 | `boolean` | `false` | 否 |
| tagType | 显式属性 → dictTag.tagType → primary | `string` | `undefined`（最终默认 primary） | 否 |
| labelKey | 对象选项的显示字段；空缺时回退 label/value | `string` | `'label'` | 否 |
| valueKey | 对象选项取值字段；按 String 比较 | `string` | `'value'` | 否 |
| tagTypeKey | 对象选项的标签类型字段 | `string` | `'elTagType'` | 否 |
| tagClassKey | 对象选项的 CSS 类字段 | `string` | `'elTagClass'` | 否 |
| emptyText | 有选中值但无匹配项时显示；空值不显示 | `string` | `''` | 否 |

## Options 数据结构

| 属性 | 说明 | 类型 | 必填 |
| --- | --- | --- | --- |
| label | 标签文本 | String | 否 |
| value | 字典值，建议显式提供唯一值 | String \| Number | 否 |
| elTagType | 标签类型，可选值：`primary`、`success`、`warning`、`danger`、`info`；无有效类型时使用组件默认类型 | String | 否 |
| elTagClass | 自定义样式类名 | String | 否 |

## Slots

| 插槽名 | 说明 | 参数 |
| --- | --- | --- |
| icon | showIcon=true 且项有 icon 才显示；option 是归一化项，含 key/label/value/tagType/tagClass/icon/color，不是原对象 | { name, color, option } |

## 注意事项

- 按字符串匹配 value，并按照 options 的顺序展示匹配项；组件不请求远程字典。
- 默认标签类型为 primary，自定义颜色优先。tagType 属性和 icon 插槽可覆盖默认展示；应用默认值可通过 dictTag.tagType、iconComponent 配置。
- 图标默认使用 SvgIcon，字体和本地 SVG symbol 资源需由应用加载。相邻标签默认间距为 10px。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { DefineComponent } from 'vue';
import type { AuraDictOption, AuraDictValue } from '../../types/dict.js';

declare const AuraDictTag: DefineComponent<{
	options?: Array<AuraDictOption | AuraDictValue>;
	value?: AuraDictValue | AuraDictValue[];
	labelKey?: string;
	valueKey?: string;
	tagTypeKey?: string;
	tagClassKey?: string;
	showIcon?: boolean;
	tagType?: string;
	emptyText?: string;
}>;

export default AuraDictTag;
```

### 配套数据类型

```ts
export interface AuraDictOption {
	[key: string]: unknown;
	label?: string;
	value?: string | number;
	elTagType?: string;
	elTagClass?: string;
	icon?: string;
	color?: string;
}

export type AuraDictValue = string | number;
export type AuraDictRequest = (dictType: string) =>
	| Array<AuraDictOption | AuraDictValue>
	| { data: Array<AuraDictOption | AuraDictValue> }
	| Promise<Array<AuraDictOption | AuraDictValue> | { data: Array<AuraDictOption | AuraDictValue> }>;
```

API 资料来自 `docs/component/dict-tag.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
