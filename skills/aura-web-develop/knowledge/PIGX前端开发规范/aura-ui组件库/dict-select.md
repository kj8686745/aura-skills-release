# AuraDictSelect 字典选择器

公共子入口 `@fxft/aura-ui/dict-select`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

使用静态选项或远程字典进行单选、多选。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraDictSelect from '@fxft/aura-ui/dict-select';
import { ref } from 'vue';

const value = ref<string | number | null | undefined>(0);
const options = [{ label: '启用', value: 0 }, { label: '停用', value: 1 }];
</script>

<template>
  <AuraDictSelect v-model="value" :options="options" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 单选 string/number，多选数组；允许 null/undefined 清空 | `string \| number \| (string \| number)[] \| null` | `undefined` | 否 |
| options | 静态字典数据数组，每个元素可以是对象（包含 `label`、`value`）或字符串 | `Array<AuraDictOption \| AuraDictValue>` | `[]` | 否 |
| placeholder | 选择器的占位文本 | `string` | `'请选择'` | 否 |
| multiple | 是否多选 | `boolean` | `false` | 否 |
| disabled | 是否禁用 | `boolean` | `false` | 否 |
| clearable | 是否可清除 | `boolean` | `true` | 否 |
| dictType | 字典类型，用于从后端加载字典数据 | `string` | `''` | 否 |
| request | (dictType) => 数组或 { data: 数组 }，可返回 Promise；优先于注入 request | `AuraDictRequest \| null` | `null` | 否 |
| labelKey | 对象选项显示字段 | `string` | `'label'` | 否 |
| valueKey | 对象选项取值字段；保留原始类型 | `string` | `'value'` | 否 |
| autoLoad | 初始化及字典类型、加载方法变化时自动加载 | `boolean` | `true` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:modelValue | ElSelect 更新时先发送 | value: string \| number \| (string \| number)[] \| null \| undefined |
| change | 紧随模型更新，参数原样传递 | 同 update:modelValue |

## Options 数据结构

| 属性 | 说明 | 类型 | 必填 |
| --- | --- | --- | --- |
| label | 选项文本 | String | 否 |
| value | 选项值，建议显式提供唯一值 | String \| Number | 否 |

## v-model

单选绑定 `string | number | null | undefined`；多选绑定数组，空值使用 `[]`。

## 注意事项

- dictType 非空时优先加载远程字典，覆盖静态 options。默认请求为 GET /admin/dict/type/{dictType}，需提供 request 属性或公共 request 配置。
- autoLoad=false 会停止自动加载，但组件没有公开的手动加载方法。
- 取值 0 有效；多选空值为 []。自定义属性可透传给 ElSelect，清空值受 ElConfigProvider 配置影响。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';
import type { AuraDictOption, AuraDictValue, AuraDictRequest } from '../../types/dict.js';

declare const AuraDictSelect: DefineComponent<{
	modelValue?: AuraDictValue | AuraDictValue[] | null;
	options?: Array<AuraDictOption | AuraDictValue>;
	placeholder?: string;
	multiple?: boolean;
	disabled?: boolean;
	clearable?: boolean;
	dictType?: string;
	request?: AuraDictRequest;
	labelKey?: string;
	valueKey?: string;
	autoLoad?: boolean;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
	'update:modelValue': (value: AuraDictValue | AuraDictValue[] | null | undefined) => void;
	change: (value: AuraDictValue | AuraDictValue[] | null | undefined) => void;
}>;

export default AuraDictSelect;
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

API 资料来自 `docs/component/dict-select.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
