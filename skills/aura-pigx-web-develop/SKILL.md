---
name: aura-pigx-web-develop
description: 按最新版 PIGX 模块联邦（综合端）规范完成 Vue 3 + Vite + TypeScript 业务开发、CRUD、接口封装、正式菜单与按钮权限、模块联邦、组件复用、样式与静态资源适配。模块联邦配置由本技能实现，并串联检查技能做改前基线与改后复检；用于 aura-pigx-cli nexus 项目及其业务远程模块。
---

# Aura PIGX 综合端业务开发

当前版本：`1.2.2`（2026-08-25）。

把本技能作为 PIGX 模块联邦（综合端）的规范执行器。先读取最新版规范，再分析和修改代码；不得用技能中的历史示例覆盖最新版规范。

## 规范优先级

发生冲突时按以下顺序处理：

1. 用户当前任务中的明确要求。
2. 当前项目源码、类型定义、生成的声明文件和实际依赖版本。
3. `knowledge/PIGX前端开发规范/` 中同步的最新版正式规范。
4. 正式规范中的专项规范、页面模式和参考样例。
5. 本技能的 `references/`、`recipes/`、`templates/` 补充资料。
6. 历史项目写法。

若低优先级资料与高优先级资料不一致，立即按高优先级资料修改，不做旧写法兼容。

## 每次任务必读

任意开发、修改或评审任务先读取：

- `knowledge/PIGX前端开发规范/README.md`
- `knowledge/PIGX前端开发规范/PIGX前端开发总览.md`
- `knowledge/PIGX前端开发规范/工程与代码生成规范.md`
- `knowledge/PIGX前端开发规范/开发检查清单.md`
- `references/message-feedback-guidelines.md`
- `references/code-comment-guidelines.md`

再按任务类型补读：

| 任务类型 | 必读资料 |
|---|---|
| 路由、菜单、隐藏页 | `knowledge/PIGX前端开发规范/路由与菜单规范.md` |
| 正式菜单、按钮权限或新业务入口 | `references/admin-menu-permission-workflow.md` |
| 模块联邦提供方/消费方 | `knowledge/PIGX前端开发规范/模块联邦开发技术规范.md` |
| 页面布局、主题、静态资源 | `knowledge/PIGX前端开发规范/样式布局与静态资源规范.md` |
| 组件选型、公司组件库 | `knowledge/PIGX前端开发规范/组件复用与公司基础组件库规范.md` |
| 查询表格页 | `knowledge/PIGX前端开发规范/页面模式/查询表格页.md` |
| 查询卡片页 | `knowledge/PIGX前端开发规范/页面模式/查询卡片页.md` |
| 左树右表页 | `knowledge/PIGX前端开发规范/页面模式/左树右表页.md` |
| 弹窗表单 | `knowledge/PIGX前端开发规范/页面模式/弹窗表单.md` |
| 详情页或抽屉 | `knowledge/PIGX前端开发规范/页面模式/详情页与抽屉.md` |
| 看板页 | `knowledge/PIGX前端开发规范/页面模式/看板页.md` |
| 同路由嵌套覆盖页 | `knowledge/PIGX前端开发规范/页面模式/Teleport嵌套页面模式.md` |
| 2D 地图 | `knowledge/PIGX前端开发规范/2D地图开发规范.md`；需要专业实现时调用 `/fmap-2d` |
| 视频 | `knowledge/PIGX前端开发规范/视频开发规范.md`；需要专业实现时调用 `/fxft-video` |
| 公司私服与组件安装 | `knowledge/PIGX前端开发规范/公司组件库下载说明/README.md` |
| 代码注释 | `references/code-comment-guidelines.md` 与 `checklists/implementation.md` |
| API/Apifox | `recipes/apifox-workflow.md`、`references/apifox-mcp-guide.md` |
| Figma | `references/figma-design-workflow.md`；设计输入不得覆盖 PIGX 工程规范 |

## 强制工作流

1. **确认项目事实**：检查 `package.json`、锁文件、`vite.config.*`、`src/hooks/`、`src/components/index.ts`、相邻业务模块和生成的类型声明，不凭历史记忆虚构 API。
2. **解析需求**：列出页面、字段、接口、权限、状态、路由/菜单、验收项和注释锚点。新建正式业务页面、菜单入口或页面操作按钮时，先生成页面菜单和每个 `v-auth` 按钮权限清单；截图、HTML 原型或 Figma 只作为业务内容和视觉输入。
3. **选择正式页面模式**：从最新版七种页面模式中选择；命中后直接以对应文档为基线，不使用旧模板覆盖。
4. **规划文件职责**：页面、页面私有组件、业务 composable、API、类型和 i18n 各司其职；只修改需求范围内文件。
5. **复用优先**：按“综合端全局组件/Hooks → `@fxft/ui-plus` → Element Plus → 页面私有业务组件 → 跨业务公共组件”的顺序选型。
6. **实现接口**：统一走 `/@/utils/request`；函数命名先遵循当前业务域相邻 API 和最新版规范，不强行套用历史命名。
7. **实现页面状态**：按适用性覆盖加载态、空态、错误态、权限、校验、防重复提交和资源清理。
8. **适配模块联邦**：涉及 remote、expose、manifest、远程菜单、shared、运行时入口或模块联邦配置时，先运行 `aura-pigx-module-federation-check` 建立基线；由本技能完成实现后再次运行其复检。远程页面不得依赖提供方 `main.ts` 的全局注册副作用。
9. **适配资源和样式**：import 资源使用 `getStaticResourceUrl`，public 资源使用 `getPublicResourceUrl`；使用主题变量并保证 Flex 高度链路。
10. **同步注释**：实现前按所选页面模式列出注释锚点，编码时同步生成和更新有价值的简体中文注释，禁止交付前集中补泛化注释。
11. **联调与验证**：新业务菜单权限流程命中时，按参考流程准备并复核菜单/按钮；仅在用户明确授权且提供目标环境、运行时凭据、租户和父菜单定位信息后调用管理端 API。再按 Apifox、构建、lint、浏览器交互、独立/远程运行和正式检查清单逐项验证。

## 消息提示与消息弹出框硬约束

业务代码只能使用：

```ts
import { useMessage, useMessageBox } from '/@/hooks/message';
```

- 普通提示调用 `useMessage().info/warning/success/error(...)`。
- 确认、警告、输入和弹出框调用 `useMessageBox().confirm/warning/success/error/info/prompt(...)`。
- 禁止从 `element-plus` 导入或调用 `ElMessage`、`ElMessageBox`、`Message`、`MessageBox`。
- 禁止自行实现消息组件、Toast、通知队列或二次消息 Hook。
- 禁止使用旧式 `const { message, messageBox } = useMessage()`；真实 Hook 分别返回消息实例和弹框实例。
- 框架维护的 `/@/hooks/message.ts` 是底层统一封装边界，业务任务不得复制、改写或绕过它。
- 用户可见消息必须使用 i18n；异常消息按最新版项目约定处理，不虚构多字段兜底。
- 仅新增、编辑、删除、启停、保存、提交、导入等用户主动发起且改变服务端状态的操作，才在请求 `catch` 中调用 `useMessage().error(...)`；字典、下拉选项、列表、详情、初始化和刷新等只读数据加载失败不弹消息，由局部错误态、空态、重试能力或上层错误策略处理。确认框取消属于正常分支，也不提示。

## 最新版核心规则

- 使用 Vue 3、TypeScript 和 `<script setup>`，具体版本以当前项目和最新版总览为准。
- 路由页必须保持单一真实元素根节点；根元素统一使用 `class="layout-padding"`，业务区域置于 `class="layout-padding-auto layout-padding-view"`，Dialog、Drawer 等弹窗可与业务区域并列置于根节点下，以兼容框架的 Transition 和运行时指令。
- 项目内部路径使用 `/@/`，避免跨层级相对路径。
- 列表页按真实 `useTable(state)` 签名传入响应式状态，并使用返回的 `tableStyle`、分页、排序和下载能力；不要从返回值中解构不存在的 `state`。
- 常规 CRUD 明确要求表格占满剩余高度时，页面容器建立纵向 Flex 高度链路，滚动父级和表格区写 `min-height: 0`，表格使用 `class="el-table--fit"` 与 `flex: 1`；不得使用 `100vh` 或固定像素表格高度。
- 新建或修改普通 `el-select` 默认添加 `filterable`；仅用户明确关闭、组件不兼容或需求明确禁止搜索时例外，并说明原因。
- 权限按钮遵循项目 `v-auth` 约定；表单提交前校验，提交期间禁用，成功后再关闭和刷新。
- import 图片、SVG、视频等先经 `getStaticResourceUrl`；Worker、decoder 等 public 资源经 `getPublicResourceUrl`。
- 不直接创建 axios 实例，不自行处理认证失效，不硬编码域名、IP、Token、Cookie、密码或部署前缀。
- Element Plus 保持本地依赖，不加入 Module Federation shared；Vue、Vue Router、Vue I18n、Pinia 按最新版模块联邦规范共享。
- 地图使用 `FxftMap`；单路和多路视频使用 `FxftVideoPlayer`、`FxftMultiVideoPlayer`，不得重复封装底层 SDK。
- 中文文档、注释、提示和新增文本文件使用 UTF-8 无 BOM。

## 正式菜单与按钮权限

新开发业务仅在新增正式业务页面、菜单入口或页面操作按钮时自动进入此流程；组件修复、隐藏页、纯后端改动和无正式入口的页面私有组件不触发。

1. 从真实页面实现、路由/组件路径和 `v-auth` 生成页面菜单及按钮权限清单。用户明确指定的页面或按钮权限编码必须原样采用；未指定时，先读取当前项目路由规范和相邻业务模块的真实 `v-auth` 命名，再按其业务域与动作规则生成，并在清单中记录生成依据。
2. 开发完成后按路径、组件和权限编码精确查重；页面菜单先创建或更新，每个按钮权限以真实页面菜单 ID 为父级。
3. 用户已明确授权并提供目标环境、管理端 Token、租户和父菜单定位信息时，按 [管理端菜单与按钮权限流程](references/admin-menu-permission-workflow.md) 调用真实项目 API 幂等创建/更新，并重新查询核验。
4. 任一条件缺失时不得外部写入；交付中列出缺少的环境、凭据、租户或父菜单信息，并保留可执行配置清单。凭据只在运行时使用，绝不落盘、写入源码、Markdown 或日志。

## 注释硬约束

- 遵循“解释 Why、保持同步、重构优先”的原则。
- 新增页面或复杂组件添加中文文件头说明；`props`、`emits`、API 函数和非显而易见的业务契约必须有中文说明。
- 大型模板按业务区块注释；复杂 `v-if`/`v-for`、卡片点击与内部操作的事件阻断说明触发场景或交互边界。
- `watch`、`nextTick`、兼容/降级、模块联邦、Teleport、地图/视频实例、资源清理和第三方样式覆盖必须说明原因或生命周期。
- 使用 `TODO:`、`FIXME:`、`PERF:`、`HACK:`、`DEPRECATED:` 标记；可关联责任人或 Issue 时补充。
- 删除废弃代码，不保留大段注释代码；修改逻辑时同步修改或删除旧注释。
- 查询卡片页按实际存在的区块保留“查询/筛选区、工具栏、卡片列表、空态、分页”中文注释锚点；其他页面模式以其正式模板中的主要区块为锚点。无对应区块时不虚构注释。
- 不按注释行数验收。交付前逐项列出“注释位置、覆盖的 Why/契约/边界”，并运行注释告警扫描；告警必须修复或在交付中说明不适用原因。

## 验证

交付前至少执行：

1. `scripts/validate-skill.ps1`（维护技能本身时）。
2. 当前项目可用的 build/typecheck 与 lint 命令。
3. `scripts/check-project-rules.ps1 -ProjectPath <项目路径>`，检查消息 API、路径别名、高风险违规和注释覆盖告警。
4. 对应最新版页面模式和 `knowledge/PIGX前端开发规范/开发检查清单.md`。
5. 浏览器核心流程；模块联邦任务同时验证独立运行和远程运行。

## 交付格式

1. **完成内容**：新增和修改文件。
2. **规范依据**：读取的最新版正式规范、页面模式和补充资料。
3. **项目适配**：真实源码、类型、Hook、组件、路由、模块联邦和命名的映射。
4. **消息检查**：确认只使用统一消息 Hook，并报告扫描结果。
5. **注释验收**：按页面模式逐项列出注释位置、覆盖的 Why/契约/边界，以及已处理或不适用的告警。
6. **联调与验证**：接口、构建、lint、浏览器及独立/远程运行结果。
7. **剩余风险**：未验证的接口、权限、远程环境、依赖或部署项。
