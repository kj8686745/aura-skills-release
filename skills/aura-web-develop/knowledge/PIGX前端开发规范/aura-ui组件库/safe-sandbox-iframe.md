# AuraSafeSandboxIframe 安全沙箱

公共子入口 `@fxft/aura-ui/safe-sandbox-iframe`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

过滤 HTML 并按 A4 页面尺寸缩放、裁剪预览。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraSafeSandboxIframe from '@fxft/aura-ui/safe-sandbox-iframe';
</script>

<template>
  <AuraSafeSandboxIframe html="<h1>静态预览</h1><p>示例内容</p>" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 必填 | 默认值 |
| --- | --- | --- | --- | --- |
| html | 要渲染的HTML内容 | `string` | 是 | `undefined` |
| baseUrl | 基础URL，用于解析相对路径资源 | `string` | 否 | `''` |
| minHeight | iframe最小高度 | `string` | 否 | `'240px'` |
| maxHeight | iframe最大高度 | `string` | 否 | `'300px'` |
| cropTopRatio | 实际计算夹取到 0.2～1；越小越突出 A4 顶部 | `number` | 否 | `0.45` |

## 注意事项

- 基准页面为 794×1123px。html 更新或容器尺寸变化会重绘；单独修改 baseUrl、minHeight、maxHeight、cropTopRatio 不会立即重绘。
- HTML 使用 DOMPurify 过滤，并配置 iframe sandbox 与 CSP。过滤与隔离受浏览器实现影响，不能据此保证任意输入安全。
- 部分 style、表格属性和相对资源地址可能被过滤；baseUrl 用于生成 base 标签，应使用应用可访问的资源地址。
- 高度支持 px、vh 和可解析数字，cropTopRatio 按 0.2～1 参与计算。组件用于局部预览，不是完整文档浏览器。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { DefineComponent } from 'vue';

declare const AuraSafeSandboxIframe: DefineComponent<{
  html: string;
  baseUrl?: string;
  minHeight?: string;
  maxHeight?: string;
  cropTopRatio?: number;
}>;

export default AuraSafeSandboxIframe;
```

API 资料来自 `docs/component/safe-sandbox-iframe.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
