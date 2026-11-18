# AuraMindMap 思维导图

公共子入口 `@fxft/aura-ui/mind-map`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

将 Markdown 标题层级转换为可缩放、可导出 PNG 的思维导图。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraMindMap from '@fxft/aura-ui/mind-map';
</script>

<template>
  <AuraMindMap text="# 示例导图" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 必填 | 默认值 |
| --- | --- | --- | --- | --- |
| text | 用于生成思维导图的文本内容，支持 Markdown 格式 | `string` | 是 | `undefined` |

## 注意事项

- 通过工具栏放大、缩小、适应画布和导出 PNG；点击节点可展开或折叠。工具栏操作不提供 ref 方法。
- 文本更新经过防抖处理；设置空文本不会清空已有导图。
- 组件最小宽度为 800px，窄屏需要调用方安排容器或滚动区域。
- PNG 导出依赖浏览器 SVG、Image 和 Canvas。外链图片、字体、跨域限制及 foreignObject 支持会影响导出，不自动内联远程资源。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { DefineComponent } from 'vue';

declare const AuraMindMap: DefineComponent<{ text: string }>;

export default AuraMindMap;
```

API 资料来自 `docs/component/mind-map.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
