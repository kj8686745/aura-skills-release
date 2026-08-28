# Figma 设计稿开发流程

## 适用场景

用户提供 Figma 链接、Figma 节点、设计稿说明，或明确要求“按 Figma 开发”时使用本流程。

## 读取规则

- Codex 使用官方 Figma MCP：设计稿转代码优先调用 `get_design_context`，必要时调用 `get_screenshot` 核对视觉细节。
- Claude Code 使用已配置的 Figma 插件或 Figma MCP，按同等流程读取节点上下文和截图。
- Figma URL 带 `node-id` 时，解析 `fileKey` 和 `nodeId`；`node-id=1-2` 需转换为 `1:2`。
- Figma URL 不带 `node-id` 时，先读取 metadata 定位页面，或要求用户提供具体节点链接；禁止猜测节点。
- Figma Make 文件按插件规则默认读取 `0:1`。
- FigJam / Slides 只作为流程、说明或演示参考，不直接当成业务页面节点编码。
- 插件不可用或权限不足时，明确说明原因，要求用户提供截图、导出资源或可访问节点；不得静默降级为凭印象开发。

## PIGX 业务区域提取

读取 Figma 后，先划分“PIGX 框架区域”和“业务内容区域”。

PIGX 框架区域不实现、不改动：

- 左侧菜单
- 顶部 Header
- 全局导航
- 头像通知区
- 面包屑
- 页签栏
- PIGX 框架布局、Module Federation 加载链路、全局主题

业务内容区域必须实现：

- `layout-padding` + `layout-padding-view` 内的页面主体
- 搜索条件、筛选项、按钮、操作入口
- 表格列、卡片、指标、弹窗、抽屉、详情区
- 空态、加载态、错误态和设计稿中明确存在的交互态
- 业务内左侧树、分类栏、筛选栏或分组导航

注意：业务内“左树右表”中的左树属于业务内容，不属于 PIGX 左侧菜单。

## 代码转换规则

- Figma 插件返回的代码只作为参考，不得直接照搬 React 或绝对定位代码。
- 最终实现必须转换为 Vue 3 + TypeScript + Element Plus + Tailwind + PIGX hooks。
- 页面根结构必须保持：

```vue
<template>
  <div class="layout-padding">
    <div class="layout-padding-view">
      <!-- Figma 业务内容区域 -->
    </div>
  </div>
</template>
```

- 命中模板时按 `templates/` 落地；未命中时按 `recipes/page-patterns.md` 和页面模式拆分。
- Figma 中的字段、按钮、筛选条件、表格列、统计指标、弹窗文案必须逐项保留，不得擅自改名、合并或删除。

## 样式映射规则

- Figma 的布局、间距、尺寸、排版、圆角、定位、响应式、显示隐藏、基础边框和阴影，优先映射为 Tailwind v3 class。
- 颜色、边框、阴影必须映射到 Element Plus 主题变量，禁止直接照搬 Figma 的 hex 色值。
- 只有以下场景才允许 SCSS：
  - `:deep()` 穿透 Element Plus 内部结构
  - 复杂兄弟/父子选择器
  - `::before` / `::after` 伪元素
  - `@keyframes` 动画
  - Element Plus 内部状态覆盖
  - Tailwind 无法表达的主题变量组合
- 新增 SCSS 前必须先确认无法用 Tailwind 表达。

## 静态资源

- Figma 中的图片、SVG、图标、插画如需用于页面展示，必须按项目静态资源规范导入。
- `import` 后用于 `src`、背景图、组件配置或图表资源前，必须调用 `getStaticResourceUrl`。
- 禁止把 Figma 资源 URL 直接写进页面展示位置。

## 验证要求

- 使用 Codex 内置浏览器（`browser:control-in-app-browser`）验证页面业务区域与 Figma 主状态一致；调用前按外部技能依赖流程检查可用性。
- 对照 Figma 逐项核对字段、筛选条件、按钮、表格列、弹窗、空态、加载态和主要交互态。
- 若 Figma 包含 PIGX 框架区域，验证时只核对业务内容区域，不要求实现框架区域。
