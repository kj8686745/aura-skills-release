# AuraColorPicker 颜色选择器

公共子入口 `@fxft/aura-ui/color-picker`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

选择颜色，支持预设颜色和恢复默认颜色。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraColorPicker from '@fxft/aura-ui/color-picker';
import { ref } from 'vue';

const value = ref<string | null | undefined>('#409EFF');
</script>

<template>
  <AuraColorPicker v-model="value" default-color="#409EFF" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 当前选中的颜色值 | `string \| null` | `undefined` | 否 |
| defaultColor | 默认颜色值，重置时恢复 | `string` | `undefined` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:modelValue | 选色、面板清空或点击重置 | value: string \| null \| undefined |

## v-model

`v-model` 绑定颜色字符串，清空和重置还可能输出 `null` 或 `undefined`。

## 注意事项

- 面板清空可输出 null；点击重置输出 defaultColor，未设置默认颜色时为 undefined。
- 输入框只读。内置预设颜色：#409EFF、#28C76F、#EA5455、#FF9F43、#01CFE8、#4A5DFF。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraColorPicker: DefineComponent<{
  modelValue?: string | null;
  defaultColor?: string;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: string | null | undefined) => void;
}>;

export default AuraColorPicker;
```

API 资料来自 `docs/component/color-picker.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
