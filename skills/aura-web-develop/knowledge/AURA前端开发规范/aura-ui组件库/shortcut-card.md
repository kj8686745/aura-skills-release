# AuraShortcutCard 快捷卡片

公共子入口 `@fxft/aura-ui/shortcut-card`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

显示带图标和文字的快捷入口，点击后由应用执行操作。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraShortcutCard from '@fxft/aura-ui/shortcut-card';
</script>

<template>
  <AuraShortcutCard icon="ele-HomeFilled" label="首页" color="#1890FF" @click="() => console.log('由业务导航')" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| icon | 显式属性 → shortcutCard.icon → menu-outlined | `string` | `undefined`（最终默认 menu-outlined） | 否 |
| label | 标签文本 | `string` | `'快捷方式'` | 否 |
| color | 自定义背景颜色，如果为空则使用随机颜色 | `string` | `''` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| click | 点击根卡片，路由跳转由宿主处理 | event: MouseEvent |

## 注意事项

- 默认图标为 menu-outlined，需加载相应字体 CSS；支持 ele-*、local-* 和图片地址。图标渲染可通过公共 iconComponent 覆盖。
- 未设置 color 时从预设背景色中随机选择；需要固定效果时显式传入 color。
- label 通过应用 $t 翻译，没有翻译服务时显示原文。click 只通知点击，不执行路由跳转。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraShortcutCard: DefineComponent<{
  icon?: string;
  label?: string;
  color?: string;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  click: (event: MouseEvent) => void;
}>;

export default AuraShortcutCard;
```

API 资料来自 `docs/component/shortcut-card.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
