# AuraDictText 字典文本

公共子入口 `@fxft/aura-ui/dict-text`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

根据单个字典值展示文字，支持标签类型、样式类和自定义颜色。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraDictText from '@fxft/aura-ui/dict-text';

const options = [{ label: '启用', value: 0 }];
</script>

<template>
  <AuraDictText :value="0" :options="options" />
</template>
```

## Attributes

| 属性 | 说明 | 默认值 | 类型 | 必填 |
| --- | --- | --- | --- | --- |
| options | 字典数组，支持对象或 string/number | `[]` | `(AuraDictOption \| string \| number)[]` | 否 |
| value | 待展示的单个值；按字符串匹配 | `undefined` | `AuraDictValue` | 否 |
| fallback | 未匹配时的文字；未传时显示原始值 | `''` | `string` | 否 |
| size | 字号；number 转为 px | `undefined` | `string \| number` | 否 |
| color | 未指定字典项颜色时的文字颜色 | `''` | `string` | 否 |
| type | 字典项类型无效或缺失时的 Element Plus 语义类型 | `undefined` | `'primary' \| 'success' \| 'info' \| 'warning' \| 'danger'` | 否 |
| ellipsis | 是否单行截断 | `false` | `boolean` | 否 |
| maxWidth | 最大宽度；number 转为 px | `undefined` | `string \| number` | 否 |
| tag | `el-text` 渲染的标签名 | `'span'` | `string` | 否 |

## 注意事项

- 字典项的 color 和 elTagType 优先于组件的 color 和 type。
- label 为空时回退显示 value；options 由调用方提供，不自动加载远程字典。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { DefineComponent } from 'vue';
import type { AuraDictOption, AuraDictValue } from '../../types/dict.js';

declare const AuraDictText: DefineComponent<{
	options?: Array<AuraDictOption | AuraDictValue>;
	value?: AuraDictValue;
	fallback?: string;
	size?: string | number;
	type?: 'primary' | 'success' | 'info' | 'warning' | 'danger';
	color?: string;
	ellipsis?: boolean;
	maxWidth?: string | number;
	tag?: string;
}>;

export default AuraDictText;
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

API 资料来自 `docs/component/dict-text.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
