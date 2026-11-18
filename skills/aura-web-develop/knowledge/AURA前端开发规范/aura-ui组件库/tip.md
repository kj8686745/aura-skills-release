# AuraTip 提示

公共子入口 `@fxft/aura-ui/tip`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

在表单项、按钮或标题旁显示提示图标和说明。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraTip from '@fxft/aura-ui/tip';
</script>

<template>
  <AuraTip content="字段说明">字段</AuraTip>
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| content | 提示文字；传入 `#content` 时优先显示插槽 | `string` | `undefined` | 否 |
| placement | Tooltip 展示方位(支持 Element Plus Tooltip 的所有位置值，传入非法值时表现由 Element Plus 决定) | `string` | `"top-start"` | 否 |
| effect | Tooltip 主题，支持 dark/light 两种主题 | `string` | `"dark"` | 否 |

## Slots

| 插槽名 | 说明 | 参数 |
| --- | --- | --- |
| default | 问号旁的触发区内容 | 无 |
| content | 提示内容，优先于 content 属性 | 无 |

## 注意事项

- content 插槽优先于 content 属性，适合多行或富文本提示。
- 问号图标与默认插槽内容共同作为 Tooltip 触发区域；placement 和 effect 控制位置与主题。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { DefineComponent } from 'vue';

declare const AuraTip: DefineComponent<{
  content?: string;
  placement?: string;
  effect?: string;
}>;

export default AuraTip;
```

API 资料来自 `docs/component/tip.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
