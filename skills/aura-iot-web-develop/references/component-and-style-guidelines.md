# 组件拆分与样式复用规范

## 目标

业务页面不能把所有逻辑、模板和样式堆在单个 `.vue` 文件中。开发时必须先检查 `templates/` 是否有匹配预设模板；模板命中时按模板执行，模板未命中且没有可参考模板结构时必须调用 `/frontend-design` 完成页面设计，再由 Agent 根据真实需求和本规范设计拆分。新增目录、页面、组件、样式文件必须遵循 `references/naming-conventions.md`。

## 页面代码体量控制

### 必须考虑拆分的信号

出现以下任一情况，必须结合真实需求判断拆分方式，不得固定套用 `form.vue/detail.vue/components`：

- 单个页面 `.vue` 超过约 300 行。
- `<template>` 中存在 2 个以上独立业务区块，例如查询区、统计卡片区、表格区、图表区、弹窗区。
- 同一个页面里有多个弹窗、抽屉、复杂表单、图表卡片。
- 一段模板结构在当前页面重复出现 2 次以上。
- 一段逻辑需要被多个页面、多个弹窗或多个模块复用。
- 样式选择器层级过深，说明结构职责不清。

### 页面内局部组件

只在当前页面或当前模块使用的组件，放在页面目录下：

```text
src/views/<module>/<page>/
├── index.vue                    # 必需：页面入口，负责编排和主数据流
├── form.vue                     # 可选：只有新增/编辑弹窗场景才需要
├── detail.vue / drawer.vue      # 可选：只有详情页/详情抽屉场景才需要
└── components/                  # 可选：只有局部区块可抽离时才需要
    ├── SearchPanel.vue
    ├── StatisticCard.vue
    └── ChartPanel.vue
```

要求：

- `index.vue` 只负责页面编排、数据流协调和主事件分发。
- 不固定要求每个页面都创建 `form.vue`、`detail.vue`、`drawer.vue`；必须根据真实业务场景决定。
- 有新增/编辑弹窗时才拆 `form.vue`；有详情页或详情抽屉时才拆 `detail.vue` / `drawer.vue`；有复杂查询区、图表卡片、统计卡片等可抽离区块时才建局部 `components/`。
- `form.vue`、`detail.vue`、`drawer.vue` 等通过 `defineExpose({ openDialog })` 或明确 props/emits 与父页面交互。
- 同模块子组件必须使用 `defineAsyncComponent` 异步引入。
- 子组件 props/emits 必须有类型定义。

### 公共组件

满足以下任一条件，应考虑抽到 `src/components/`：

- 跨 2 个以上页面复用。
- 与业务域弱相关，例如分页工具栏、查询树、指标卡片、通用空态、图表容器、上传包装。
- 后续明确会扩展到多个模块。

公共组件要求：

- 创建公共组件前必须先读取 `templates/components/README.md`，并按场景选择展示、`defineModel`、插槽、表单项、弹窗/抽屉、列表/卡片等模板。
- 目录结构：`src/components/<ComponentName>/index.vue`。
- 如有复杂类型，增加 `types.ts`。
- 如有内部组合逻辑，增加 `useXxx.ts`。
- 不直接耦合某个页面 API；数据通过 props/emits 或 slots 注入。
- 文案、权限、接口路径不得写死到公共组件中。

## 组件拆分强制顺序

1. **弹窗/抽屉必须拆分**：新增、编辑、详情、授权、绑定等弹窗不要堆在主页面。
2. **图表卡片必须拆分**：图表容器、指标卡片、看板区块拆成独立组件，并使用 `useECharts`。
3. **查询区按复杂度拆分**：复杂查询表单必须拆成 `SearchPanel.vue`，通过 `v-model` 或 emits 同步查询条件。
4. **表格列复杂时拆分渲染组件**：复杂状态、操作区或嵌套展示必须拆成局部组件。
5. **复用后再公共化**：只在当前页面用的先放页面 `components/`，确认跨模块复用后必须移动到 `src/components/`。

## 样式复用规范

CSS 与 Tailwind 细则必须读取 `references/css-tailwind-guidelines.md`；示例代码必须查看 `examples/`。

### 当前项目公共页面样式入口

可复用页面级样式统一维护在：

`src/styles/page.scss`

并通过 `src/styles/index.scss` 引入。


### 页面模块样式拆分

如果单个页面或页面模块的样式很多，但样式只服务于该页面模块，不具备跨页面复用价值，必须拆到页面模块自己的样式目录中：

```text
src/views/<module>/<page>/
├── index.vue
├── components/
└── styles/
    ├── index.scss      # 页面模块样式入口
    ├── search.scss     # 查询区样式
    ├── table.scss      # 表格区样式
    └── chart.scss      # 图表区样式
```

使用要求：

- 页面模块私有样式必须放在当前页面目录的 `styles/` 下，不要塞进全局 `src/styles/page.scss`。
- `src/styles/page.scss` 只放跨页面复用的公共样式。
- 页面模块样式文件必须按业务区块命名，例如 `search.scss`、`table.scss`、`report-card.scss`、`chart.scss`，不得使用 `style1.scss`、`common.scss` 等过泛命名。
- 页面模块样式较少时，可以继续写在当前组件 `<style scoped>` 中。
- 页面模块样式较多时，组件内只保留：

```vue
<style scoped lang="scss">
@use './styles/index.scss';
</style>
```

- 拆分后的样式仍然必须通过页面根类限定作用域，避免污染其它页面。
- 不得为了省事把页面私有样式写成全局样式。

### 哪些样式应进入 `src/styles/page.scss`

- 页面通用容器，如 `.page-card`、`.page-section`、`.page-toolbar`。
- 查询区、工具栏、表格区、分页区通用布局。
- 看板卡片、指标卡片、图表容器通用样式。
- 常用状态文本、辅助说明、空态容器。
- 多个页面会复用的 flex/grid 辅助结构。

### 哪些样式留在组件 scoped 中

- 只服务于当前组件的特殊布局。
- 与组件 DOM 结构强绑定的样式。
- 一次性视觉微调。
- 需要 `:deep()` 穿透 Element Plus 的局部样式。

### 禁止

- 禁止在多个页面重复复制同一段 `.page-card`、工具栏、图表容器样式。
- 禁止在业务页面写大量全局 class。
- 禁止为了一个页面把所有公共样式都塞进 `src/styles/main.scss`。
- 禁止写死主题色，必须使用 Element Plus CSS 变量。

## 开发前强制判定

每次新增页面前必须逐项判定并落实：

| 判定项 | 必须动作 |
|--------|----------|
| 页面是否包含弹窗、抽屉、详情、图表、复杂查询区等独立区块 | 有则必须拆成对应局部组件；没有该场景则不创建无意义文件 |
| 区块是否会被当前模块内多个页面复用 | 有则必须放到页面模块 `components/` 或模块级组件目录 |
| 区块是否会跨模块/跨页面复用 | 有则必须沉淀到 `src/components/` 公共组件 |
| 样式是否跨页面复用 | 有则必须写入 `src/styles/page.scss` |
| 样式是否只属于当前页面但数量较多 | 有则必须拆到 `src/views/<module>/<page>/styles/` |
| 是否存在现成公共组件或技能内置封装 | 有则必须复用/补齐，不得重复实现 |
| 新增文件/目录/组件/store/hooks/样式是否已按业务语义命名 | 必须对照 `references/naming-conventions.md` 检查命名依据 |
| 是否存在 VueUse 可替代的手写 DOM/事件/状态逻辑 | 有则必须调用 `/vueuse-functions` 并使用对应 VueUse 函数 |
