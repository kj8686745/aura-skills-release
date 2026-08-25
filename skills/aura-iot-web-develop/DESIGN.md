# aura-iot-devWeb-develop 设计方案

## 1. 设计目标

本技能的目标是把 `foundation-dev-web` 的业务开发规范沉淀为一个可执行、可维护、可扩展的 Claude Code 技能包。

核心目标：

1. 让 Agent 在业务开发前必须读取项目规范。
2. 让页面开发先匹配预设模板，避免自由发挥导致结构不一致；没有模板参考时调用 `/frontend-design` 完成页面设计。
3. 让缺失封装、页面模式、CSS、VueUse、命名规范、验证流程都有明确落点。
4. 让规范维护在技能内部，避免业务项目和技能双源维护。
5. 让技能接近高质量技能的结构：入口、知识库、模板、清单、配方、示例、脚本、说明文档齐全。

## 2. 设计原则

### 2.1 入口轻量，知识分层

`SKILL.md` 只承担入口和强制流程，不堆大量细节。  
细节按用途拆到：

- `knowledge/`
- `templates/`
- `references/`
- `checklists/`
- `recipes/`
- `examples/`
- `scripts/`

这样可以降低 Agent 首次读取成本，也便于后续扩展。

### 2.2 先匹配模板，规范兜底

页面开发先查 `templates/`。

- 命中模板：按模板开发。
- 未命中具体页面模板、没有可参考模板结构：调用 `/frontend-design` 完成页面设计，再按 `references/`、`checklists/`、`recipes/` 落地实现。

这样避免把所有页面强行拆成固定文件结构。

### 2.3 命名先按业务语义

新增 API、页面、路由、组件、store、hooks、样式文件时，必须先根据业务域、业务对象、功能动作命名，再考虑技术类型。命名规范集中维护在 `references/naming-conventions.md`，避免出现 `online.ts`、`api.ts`、`Page.vue`、`useData` 等维护成本高的过泛命名。

### 2.4 强制项目封装

项目级封装不是建议项，而是强制项：

- 查询表格：`useTable`
- 图表：`useECharts`
- 消息弹窗：`useMessage` / `useMessageBox`
- 表单重置：`useForm`

这些封装统一项目交互、样式和上下文行为。

### 2.5 CSS 先 Tailwind，颜色走主题变量

样式规则采用强制顺序：

1. Tailwind 工具类。
2. SCSS 兜底。
3. Element Plus 主题变量约束颜色。

这样可以减少重复 CSS，并保证主题一致性。

### 2.6 VueUse 作为组合式逻辑标准库

当前项目已具备 `@vueuse/core`。  
DOM、浏览器 API、防抖节流、异步状态、定时器等场景必须先调用 `/vueuse-functions` 判断，避免手写重复逻辑。

### 2.7 验证闭环

技能把验证纳入 `checklists/validation.md`：

- 命令验证。
- 浏览器验证。
- qiankun 验证。
- 交付格式。

页面验证必须使用 `/agent-browser`。

## 3. 目录设计

```text
aura-iot-devWeb-develop/
├── SKILL.md
├── README.md
├── USAGE.md
├── DESIGN.md
├── knowledge/
├── references/
├── checklists/
├── recipes/
├── templates/
├── examples/
└── scripts/
```

### 3.1 SKILL.md

技能入口，包含：

- 任务类型到资料的映射。
- 技能目录结构。
- 强制工作流。
- 当前项目硬性约束。
- 技能协作关系。
- 交付格式。

### 3.2 knowledge/

维护内置知识库，包括页面模式、代码约束、布局规范、组件复用规范等。

### 3.3 templates/

维护可直接匹配的预设模板：

- 查询表格页。
- 弹窗表单。
- 看板图表卡片。

未来可以继续增加：

- 左树右表。
- 详情抽屉。
- 查询卡片页。
- 多步骤向导。
- 权限配置页。

### 3.4 references/

维护专题规范：

- 当前项目画像。
- 技能架构。
- 组件拆分与样式复用。
- 命名规范。
- CSS 与 Tailwind 强制规范。

### 3.5 checklists/

维护执行清单：

- 开发前检查。
- 实现检查。
- 验证检查。

### 3.6 recipes/

维护落地配方：

- hooks 标准。
- 页面模式适配。
- VueUse 选型。

### 3.7 examples/

维护示例代码：

- Tailwind + Element Plus 主题变量示例。
- SCSS 模块样式示例。
- 页面模块样式目录结构示例。

### 3.8 scripts/

维护辅助脚本：

- 项目扫描。
- 技能结构校验。

## 4. 工作流设计

```text
用户需求
  ↓
识别任务类型
  ↓
复杂任务调用 /planning-with-files-junmoxiao
  ↓
读取 SKILL.md
  ↓
新页面先查 templates/
  ↓
未命中具体页面模板且没有参考结构时调用 /frontend-design
  ↓
读取 knowledge / references / checklists / recipes
  ↓
需要 VueUse 调用 /vueuse-functions
  ↓
需要 UI/UX 评审或用户要求体验优化时调用 /ui-ux-pro-max
  ↓
实现代码
  ↓
命令验证 + agent-browser 验证
  ↓
按交付格式输出
```

## 5. 质量门禁

技能质量通过以下方式控制：

- `scripts/validate-skill.ps1` 扫描结构和禁用词。
- `checklists/implementation.md` 控制实现规则。
- `checklists/validation.md` 控制验证闭环。
- `examples/` 提供可模仿的正确写法。

## 6. 后续扩展计划

- 增加更多页面模板。
- 增加公共组件模板。
- 增加 API 封装模板。
- 增加 Pinia store 模板。
- 增加 qiankun 验证脚本。
- 增加 Tailwind 主题变量扫描脚本。
- 增加页面复杂度扫描脚本。
