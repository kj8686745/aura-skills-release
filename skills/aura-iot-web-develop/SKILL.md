---
name: aura-iot-web-develop
description: 物联中枢云底座业务开发规范技能，包含项目规范知识库、页面模板、开发清单、落地配方和示例。
compatibility: Claude Code；Windows PowerShell；Vue 3 + Vite + TypeScript + Element Plus + qiankun 项目
metadata:
  version: "1.0.0"
  type: project-development-standard
  project: foundation-dev-web
  stack: Vue 3 / Vite / TypeScript / Element Plus / Pinia / Vue Router / qiankun / TailwindCSS
---
# Aura IOT DevWeb 业务开发规范

你是 `foundation-dev-web` 的业务开发规范执行器。后续开发必须使用本技能目录下维护的内置知识库和落地规则。

## 重要：先读哪些文件

按任务类型选择读取：


| 任务类型            | 必读文件                                                                                                                                              |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| 任意业务开发        | `references/project-profile.md`、`references/css-tailwind-guidelines.md`、`references/naming-conventions.md`、`checklists/pre-development.md`                              |
| 新页面              | `templates/README.md`、命中的具体模板、`recipes/page-patterns.md`、`knowledge/代码约束/页面模式/` 中对应文档；没有模板参考时调用 `/frontend-design` 完成页面设计 |
| API 封装            | `templates/api-module.md`、`src/api/index.ts`、`src/utils/request.ts`                                                                                 |
| Pinia 状态          | `templates/pinia-store.md`、`src/stores/user.ts`                                                                                                      |
| 公共组件            | `templates/components/README.md`、命中的具体组件模板、`references/component-and-style-guidelines.md`                                                  |
| 表格/图表/弹窗/表单 | `recipes/hooks-standards.md`、`references/component-and-style-guidelines.md`、`references/css-tailwind-guidelines.md`、`checklists/implementation.md` |
| Vue 组合式逻辑      | 先调用`/vueuse-functions`，再读 `recipes/vueuse-decision-guide.md`                                                                                    |
| UI/UX 质量          | 仅用户明确要求美化、设计评审、体验优化时调用 `/ui-ux-pro-max`                                                                                         |
| 无模板页面设计      | 新页面没有命中 `templates/` 中的具体页面模板、没有可参考模板结构时，调用 `/frontend-design` 完成页面设计                                               |
| 页面验证            | 调用`/agent-browser`                                                                                                                                  |

## 高质量技能结构约定

本技能按“入口指令 + 内置知识库 + 预设模板 + 检查清单 + 落地配方 + 示例代码 + 辅助脚本 + 使用说明 + 设计方案”的结构维护。
这样做的目标是让技能成为可执行工作流包，而不是单一提示词文件。

## 技能目录结构

```text
aura-iot-devWeb-develop/
├── SKILL.md                         # 技能入口
├── README.md                        # 技能总览
├── USAGE.md                         # 使用说明
├── DESIGN.md                        # 设计方案
├── knowledge/                       # 内置知识库，后续规范维护在这里
│   ├── README.md
│   └── 代码约束/                    # 技能内置规范库
├── references/                      # 当前项目画像与架构说明
│   ├── project-profile.md
│   └── skill-architecture.md
├── checklists/                      # 开发/实现/验证清单
│   ├── pre-development.md
│   ├── implementation.md
│   └── validation.md
├── recipes/                         # 落地配方
│   ├── hooks-standards.md
│   ├── vueuse-decision-guide.md
│   └── page-patterns.md
├── templates/                       # 预设模板
│   ├── README.md                    # 模板索引
│   ├── api-module.md                # API 封装模板
│   ├── pinia-store.md               # Pinia 状态模板
│   └── components/                  # 公共组件分场景模板
├── examples/                        # 预留示例目录
└── scripts/
    ├── scan-project.ps1             # 项目结构与依赖扫描脚本
    ├── validate-qiankun.ps1         # qiankun 静态验证脚本
    ├── scan-tailwind-theme-vars.ps1 # Tailwind 主题变量扫描脚本
    ├── scan-page-complexity.ps1     # 页面复杂度扫描脚本
    └── validate-skill.ps1           # 技能结构与禁用词扫描脚本
```

## 强制工作流

1. **识别任务类型**：页面、接口、路由、状态、样式、hooks、组件、验证。
2. **先检查预设模板**：新页面/新模块必须先查看 `templates/`，命中模板则按模板开发；没有命中具体页面模板、没有可参考模板结构时，必须调用 `/frontend-design` 完成页面设计，再结合规范落地实现。
3. **命名先按业务语义**：新增 API、页面、路由、组件、store、hooks、样式文件前，必须读取 `references/naming-conventions.md`，根据业务域、业务对象和功能动作命名；不得使用过泛命名。
4. **读取对应内置资料**：不要只看本文件，必须按上表读取知识库/清单/配方。
5. **结合当前项目画像适配**：不得照搬旧 PIGX 路径和结构。
6. **CSS 与样式强制规则**：能用 Tailwind 的必须使用 Tailwind；Tailwind 表达不了的才写 SCSS；Tailwind 颜色和 SCSS 颜色都必须使用 Element Plus 主题变量；示例见 `examples/`，详见 `references/css-tailwind-guidelines.md`。
7. **组件拆分与样式复用**：单页面代码不能过重；先按 `templates/` 匹配页面模板，再根据真实需求决定拆分方式；只有需求中确实存在弹窗、抽屉、详情、图表、复杂查询区等独立区块时才拆对应组件；跨页面复用时抽到 `src/components/`；多页面复用样式写入 `src/styles/page.scss`；页面模块私有样式较多时拆到页面模块 `styles/` 目录，详见 `references/component-and-style-guidelines.md`。
8. **必须复用封装**：
   - API：必须使用 `src/utils/request.ts` 和 `src/api/`，并按 `templates/api-module.md` 封装
   - Pinia：跨页面共享状态按 `templates/pinia-store.md` 设计，`src/stores/user.ts` 仅作为用户态参考
   - 公共组件：跨页面复用组件按 `templates/components/README.md` 选择分场景模板
   - 查询表格：必须使用 `src/hooks/table.ts` 的 `useTable`
   - 图表：必须使用 `src/hooks/echarts.ts` 的 `useECharts`
   - 消息弹窗：必须使用 `src/hooks/message.ts` 的 `useMessage` / `useMessageBox`
   - 表单重置：必须使用 `src/hooks/form.ts` 的 `useForm`
9. **必须使用 VueUse**：DOM、浏览器 API、防抖节流、异步状态、定时器等先调用 `/vueuse-functions` 判断。
10. **缺失封装按内置配方补齐**：按 `recipes/hooks-standards.md` 补齐并适配。
11. **页面验证必须用 agent-browser**：涉及页面、路由、交互、样式、下载/导入导出等浏览器行为时，必须调用 `/agent-browser` 验证；只有该技能不可用或环境不满足时，才能如实说明原因并降级验证。
12. **验证并交付**：按 `checklists/validation.md` 执行并汇报。

## 当前项目硬性约束

- 项目内部路径使用 `@/`，不要使用 `/@/`。
- 不移除 `.foundation-dev-web` 根类。
- 不移除 Element Plus `aura` namespace。
- 不破坏 `postcss.config.js` 中业务样式前缀和 Element Plus 主题变量桥接。
- 不破坏 qiankun 生命周期和 base/routerBase/basename 适配。
- 新增文件、目录、路由、组件、store、hooks、样式文件必须按 `references/naming-conventions.md` 使用业务语义命名，不得使用 `api.ts`、`online.ts`、`Page.vue`、`useData`、`common.scss` 等过泛命名。
- 页面不得直接使用 axios，必须走 `src/utils/request.ts` 和 `src/api/`。
- 当前未确认存在 `v-auth`、完整 i18n、完整 PIGX 全局组件时，不得凭空生成。
- 单页面代码不能过重；如何拆分必须看真实需求和预设模板，不能固定创建无意义的 `form.vue/detail.vue/drawer.vue`。
- CSS 必须先用 Tailwind；Tailwind 无法表达时才写 SCSS。
- Tailwind 颜色、SCSS 颜色、背景、边框、阴影必须使用 Element Plus 主题变量。
- 可复用页面样式维护在 `src/styles/page.scss`；页面模块私有样式较多时必须拆到该页面模块的 `styles/` 目录。
- 不在没有用户授权的情况下安装新依赖。
- 不把 token、Cookie、密码写入代码、日志或规划文件。

## 与其它技能协作

以下技能仅在当前会话已安装且出现在可用技能列表时调用；如果不可用，不得假装已调用。

当任务需要协作技能但该技能未安装或未出现在可用技能列表时，按以下流程处理：

1. 先检查 `/find-skills` 是否可用。
2. 如果 `/find-skills` 也不可用，必须先提示用户授权安装；用户授权后执行以下命令安装：

   ```bash
   npx skills add https://github.com/vercel-labs/skills --skill find-skills
   ```
3. 安装 `/find-skills` 后，通过 `/find-skills` 查找当前任务需要的技能，并按 `/find-skills` 的结果和用户授权安装对应技能。
4. 安装完成后再调用对应技能继续任务；如果安装失败或仍不可用，必须如实说明，并按通用能力继续处理或等待用户进一步指示。

- `/vueuse-functions`：VueUse 组合式函数选型与用法。
- `/agent-browser`：页面、交互、路由和控制台验证。
- `/frontend-design`：当新页面没有命中具体页面模板、没有可参考模板结构时，用于完成页面设计；模板命中时不在本技能默认流程中调用。
- `/ui-ux-pro-max`：用户明确要求 UI/UX 评审、体验优化、视觉质量检查时调用。
- `/find-skills`：遇到未知专业能力时主动查找配合技能。

## 交付格式

完成任务后按以下结构回复：

1. **完成内容**：列出新增/修改文件。
2. **使用的技能资料**：列出命中的 `templates/`；如果未命中模板，说明使用了哪些 `knowledge/`、`references/`、`checklists/`、`recipes/`；涉及样式时列出使用的 `examples/`。
3. **项目适配点**：说明如何把通用知识库改造成当前项目实现，并说明新增 API、页面、路由、组件、store、hooks、样式文件的命名依据。
4. **复用封装**：说明使用/补齐了哪些 hooks、组件或 VueUse 函数。
5. **CSS 说明**：说明哪些样式使用 Tailwind，哪些样式写了 SCSS，以及使用了哪些 Element Plus 主题变量。
6. **验证结果**：列出命令、`/agent-browser` 页面验证和结果；如未能调用 `/agent-browser`，必须说明原因和降级验证方式。
7. **剩余风险**：依赖、登录态、后端接口、qiankun 底座等未验证项。
