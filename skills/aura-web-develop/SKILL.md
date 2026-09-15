---
name: aura-web-develop
description: 按最新版 PIGX 模块联邦（综合端）规范完成 Vue 3 + Vite + TypeScript 业务开发、CRUD、接口封装、正式菜单与按钮权限、组件复用、统一视觉风格与样式资源适配。模块联邦配置由本技能实现，并串联检查技能做改前基线与改后复检；用于 aura-pigx-cli nexus 项目及其业务远程模块。
---
# Aura PIGX 综合端业务开发

当前版本：`1.2.25`（2026-09-14）。

把本技能作为 PIGX 模块联邦（综合端）的规范执行器。先读取最新版规范，再分析和修改代码；不得用技能中的历史示例覆盖最新版规范。

## 首次调用提示

当前会话首次命中本技能时，简要说明：它负责 PIGX 业务实现；请提供页面/接口/权限或模块联邦目标；地图和视频会串联可用专项技能；示例为“新增设备 CRUD 页面并创建正式菜单和按钮权限”。同一会话后续不重复说明；用户询问“怎么用”“帮助”或“示例”时读取并输出 [使用说明](USAGE.md) 的相关部分。

## 外部技能依赖预检

准备调用任何其它技能前，必须先检查当前环境的可用技能列表，不得仅凭目录名或历史安装记录假定存在。规则适用于 `$frontend-design`、`fmap-2d`、`fxft-video`、`aura-module-federation-check`、`vueuse-functions` 以及后续参考资料新增的任何外部技能。

若目标技能未安装或未出现在可用技能列表中，立即告诉用户缺少的技能、用途和对当前任务的影响，并询问是否安装；未经用户明确授权不得执行安装。用户同意后，按当前环境的技能安装流程安装并重新检查可用性；用户拒绝或安装失败时，可降级的流程按 PIGX 本地规范继续并在交付中说明，必需技能缺失时只暂停受影响的专项分支。详细规则见 [外部技能依赖流程](references/skill-dependency-workflow.md)。

## Codex 内置浏览器自查

前端页面业务开发或可见交互改造完成后，必须明确告诉用户“现在使用 Codex 内置浏览器进行页面自查”，并读取、遵循当前环境的 `browser:control-in-app-browser` Skill。该名称代表浏览器 Skill，不是可直接调用的 MCP 工具；实际操作必须通过该 Skill 指定的 `browser-client.mjs` 和 `mcp__node_repl__js` 完成。用户明确说“Codex 内置 Browser”或要求接管 Codex 内已打开页面时，选择 `iab`，优先复用当前会话中 URL 匹配的已有标签页和登录状态，不要新建重复标签页。不得改用 `computer-use` 接管 ChatGPT/Codex 桌面窗口，也不得用外部 Chrome、`agent-browser` 或仅看源码代替。每次导航、点击、输入或滚动后，必须重新读取 DOM/可访问状态，再决定下一步；标签页失效时只重新获取该 `iab` 会话中的标签页，不要切换浏览器。浏览器 Skill 不可用时必须说明未完成浏览器自查，不得声称验证通过。完整流程见 [Codex 内置浏览器走查](references/codex-browser-review-workflow.md)。

若用户提供可访问的原型、设计稿预览或业务参考链接，编码前使用 Codex 内置浏览器建立“原型字段/操作/状态 → 实现”的对照表；完成后同时访问实现页与原型，按业务内容、布局层级、字段与操作、主要状态、响应式和用户明确意见逐项对照。原型存在不合理、缺失或与真实接口冲突时不得自行改良，必须记录差异并交由用户决策；用户明确提出的取舍、差异接受项或验收意见优先，不能被原型默认表现覆盖。

用户没有明确走查意见时，不擅自替用户确认有主观取舍的视觉差异；输出走查结果、实现一致项、差异项、风险和需要用户决策的选项。浏览器技能不可用、页面无法启动、原型无权限或链接不可访问时，明确说明未完成项和原因，不得声称走查通过。

### 浏览器显式调用与任务连续性

- 用户以 `[@浏览器](plugin://browser@openai-bundled)` 点名时，必须选择 Codex In-App Browser；这是稳定的显式选择方式，不依赖 `/browser` 是否注册为斜杠命令。
- 优先复用用户提及或当前会话中 URL 匹配的标签页和登录态；不新建重复标签页，不改用 Chrome、Computer Use 或源码检查替代页面走查。
- 状态询问、走查结论、菜单定位、图片生成失败、首次构建错误或浏览器验收结果都是同一开发任务的子步骤。除非用户明确要求暂停、停止或只报告状态，否则回答后立即继续剩余可执行步骤。
- 只有页面、私有组件、接口或 mock、i18n、模块联邦 expose、格式化、构建、必要菜单权限、浏览器验收和用户明确的交付项均完成，才能作为开发任务结束。

## Prettier 代码格式化

每次新增、修改或重构代码完成后，必须自动执行 Prettier，再进入 build、typecheck、lint 和浏览器验证。先读取项目的 Prettier 配置和 `package.json` 脚本，识别锁文件对应的包管理器；优先调用项目已有的 `format` 或 `format:write` 脚本，否则使用该项目本地安装的 Prettier 格式化本次修改且受支持的代码文件。不得只凭全局 Prettier 或记忆中的默认配置执行。

格式化仅覆盖本次修改的受支持文件，并遵循 `.prettierignore`，不格式化锁文件、生成物和第三方目录。项目未安装本地 Prettier 时不得静默安装；应说明格式化未执行，并在交付中记录缺失原因。格式化完成后执行 `git diff --check`，再继续后续验证。详细命令选择见 [Prettier 代码格式化流程](references/prettier-formatting-workflow.md)。

## 业务视觉设计协作

当任务新增或改造用户可见的业务页面、CRUD、看板、地图/视频容器或跨页面视觉组件时，在页面实现前调用 `$frontend-design`（当前环境以技能列表中的 `frontend-design/SKILL.md` 为准；用户指定的 `C:\Users\83979\\.cc-switch\\skills\\frontend-design\\SKILL.md` 可作为同一规范来源）。先基于业务对象、受众和页面单一目标确定视觉方向，再形成颜色、字体、间距、圆角、层级和动效令牌；实现后按该技能要求进行一次自我评审，检查是否仍像模板、信息层级是否清晰、键盘焦点和 reduced-motion 是否可用。

调用 `$frontend-design` 时，不得把“左侧强调条”作为标题、卡片或内容分区的默认装饰反复复用。只有它确实表达选中、状态、分类或项目既有设计语言时才使用，并说明其语义；一般层级优先通过字体、留白、布局、分隔、背景或克制的图标建立。完成后的设计自评必须检查同页及同业务模块是否存在无语义的左侧强调条堆叠，发现模板化重复时调整后再进入浏览器走查。

`$frontend-design` 只负责视觉方向与体验评审，不能替代 PIGX 页面模式、组件复用、主题变量、消息 Hook、权限或模块联邦规范。纯后端改动、隐藏页、无用户界面的组件修复和仅审计任务不触发该协作。若当前环境没有该技能，先提示用户安装；用户拒绝或安装失败后，才按 PIGX 样式规范降级实现并在交付中说明。

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


| 任务类型                             | 必读资料                                                                                                                             |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| 路由、菜单、隐藏页                   | `knowledge/PIGX前端开发规范/路由与菜单规范.md`                                                                                       |
| 正式菜单、按钮权限或新业务入口       | `references/admin-menu-permission-workflow.md`                                                                                       |
| 模块联邦提供方/消费方                | `knowledge/PIGX前端开发规范/模块联邦开发技术规范.md`                                                                                 |
| 页面布局、主题、静态资源             | `knowledge/PIGX前端开发规范/样式布局与静态资源规范.md`                                                                               |
| 用户可见页面设计风格统一             | `$frontend-design`、`references/frontend-design-workflow.md`；先定视觉方向和令牌，限制无语义的左侧强调条重复，完成后自评             |
| 组件选型、公司 UI 规范               | `knowledge/PIGX前端开发规范/组件复用与公司基础组件库规范.md`                                                                         |
| 查询表格页                           | `knowledge/PIGX前端开发规范/页面模式/查询表格页.md`                                                                                  |
| 查询卡片页                           | `knowledge/PIGX前端开发规范/页面模式/查询卡片页.md`                                                                                  |
| 左树右表页                           | `knowledge/PIGX前端开发规范/页面模式/左树右表页.md`                                                                                  |
| 弹窗表单                             | `knowledge/PIGX前端开发规范/页面模式/弹窗表单.md`                                                                                    |
| 详情页或抽屉                         | `knowledge/PIGX前端开发规范/页面模式/详情页与抽屉.md`                                                                                |
| 看板页                               | `knowledge/PIGX前端开发规范/页面模式/看板页.md`                                                                                      |
| 同路由嵌套覆盖页                     | `knowledge/PIGX前端开发规范/页面模式/Teleport嵌套页面模式.md`                                                                        |
| 2D 地图                              | `knowledge/PIGX前端开发规范/2D地图开发规范.md`；先检查并按需提示安装 `/fmap-2d`，再核验 `@fxft/ui-plus` 版本是否满足所用 API 的要求  |
| 视频                                 | `knowledge/PIGX前端开发规范/视频开发规范.md`；先检查并按需提示安装 `/fxft-video`，再核验 `@fxft/ui-plus` 版本是否满足所用 API 的要求 |
| 公司 UI 规范依赖安装                 | `knowledge/PIGX前端开发规范/公司组件库下载说明/README.md`                                                                            |
| 代码注释                             | `references/code-comment-guidelines.md` 与 `checklists/implementation.md`                                                            |
| API/Apifox                           | `recipes/apifox-workflow.md`、`references/apifox-mcp-guide.md`                                                                       |
| Figma                                | `references/figma-design-workflow.md`；设计输入不得覆盖 PIGX 工程规范                                                                |
| 页面开发后浏览器验收、可访问原型比对 | `references/codex-browser-review-workflow.md`；明确使用 Codex 内置浏览器                                                             |

## 强制工作流

1. **确认项目事实与技能依赖**：检查 `package.json`、锁文件、`vite.config.*`、`src/hooks/`、`src/components/index.ts`、相邻业务模块和生成的类型声明；列出本任务将调用的外部技能并检查可用性，缺失时先提示用户安装，不凭历史记忆虚构 API 或假称已调用技能。
2. **解析需求**：列出页面、字段、接口、权限、状态、路由/菜单、验收项和注释锚点。新建正式业务页面、菜单入口或页面操作按钮时，先生成页面菜单和按唯一权限编码归并的 `v-auth` 按钮权限清单；同一编码的多处按钮引用只对应一条后台权限记录。截图、HTML 原型或 Figma 只作为业务内容和视觉输入。用户可见页面同时进入 `$frontend-design` 设计协作。
3. **选择正式页面模式**：从最新版七种页面模式中选择；命中后直接以对应文档为基线，不使用旧模板覆盖。
4. **规划文件职责**：编码前先列出路由页、页面私有组件、业务 composable、API、类型和 i18n 的职责清单；只修改需求范围内文件。路由页只负责页面布局、查询主状态和子组件编排，不得为了“先跑通”临时内联多个业务弹窗后再等待评审发现。

### i18n 分层与去重

- 按复用范围放置文案：全项目通用文案使用 `src/i18n/`；同一业务域内两个及以上页面/模块共用的文案使用 `src/views/<业务域>/i18n/`；仅单个页面或私有组件使用的文案才放入其业务目录 `i18n/`。
- 新增 key 前必须依次搜索全局、业务域和当前模块语言包；已存在且语义一致的 key 直接复用，禁止在相邻业务模块重复定义同义文案。发现同类文案已在多个模块出现或预期跨模块复用时，应按复用范围主动提取到全局或业务域公共语言包，并同步替换本次涉及模块的重复 key。
- 业务域共享 key 使用业务域命名空间，例如 `iot.clearFilter`；不得以页面名称承载跨页面通用语义。中英文语言包必须同步维护。
- 不为整理目录而无差别迁移历史 key；仅在本次需求涉及的模块中合并已确认重复、且不影响远程暴露和现有调用契约的文案。

### 枚举、字典、国际化与占位硬约束

- 编码前解析 API/OpenAPI、TypeScript 类型和相邻业务契约中的枚举与 `dictKey`，逐字段列出“筛选、表格、详情、表单”的渲染方式。接口类型中带字典的字段必须保留 `/** @dictKey <key> */` 注释，作为可扫描契约。
- 有字典的筛选与表单必须使用 `DictSelect` 或项目字典选项；表格状态使用 `DictTag`，详情只读展示使用 `DictText`。禁止硬编码枚举选项，禁止直接输出对应 `*Name` 快照；无字典的真实名称字段除外。
- 业务 `.vue/.ts` 中用户可见文案一律使用 `t()` / `$t()`，覆盖 label、title、placeholder、按钮、列名、卡片标题与说明、Dialog/Drawer、空态、校验与消息。注释、接口/字典返回值、后端异常、mock 数据和 i18n 文件除外。
- 新文案先复用 `common`；跨两个及以上业务模块、但不属于全局 common 的文案上提到业务域公共 `i18n/`；中英文 key 同步存在。不得在页面 i18n 重复定义已有 common 或业务域文案。
- 每个可编辑或筛选的 `el-input`、`el-select`、`el-date-picker`、`el-input-number`、`el-autocomplete` 必须具备 i18n placeholder。确无占位语义时添加 `data-placeholder-exempt`，并以相邻中文注释说明原因。
- 行内查询表单中，查询、重置、导出、视图切换等每个独立操作各占一个无标签 `el-form-item`；禁止在同一无标签 `el-form-item` 内堆叠多个 `el-button` 或 `el-radio-group`。间距只由表单 `gap` 管理，不使用按钮相邻 margin 或负 `margin-bottom` 补偿。
- 交付前必须运行 `scripts/check-project-rules.ps1 -ProjectPath <项目路径> -StrictUiContracts`。直接中文、缺少 placeholder、i18n key 未在 zh/en 同步、或已声明 `@dictKey` 字段的 `*Name` 直出均为错误，不得进入 build 或交付。
5. **复用优先**：按“综合端全局组件/Hooks → Element Plus → 页面私有业务组件 → 跨业务公共组件”的顺序选型。业务 UI 需要进入 Element Plus 选型阶段时，必须先使用 Codex 内置浏览器访问 [Element Plus 组件总览](https://element-plus.org/zh-CN/component/overview)，再阅读候选组件的官方文档，核对当前项目版本支持的 Props、Events、Slots 和公开方法；存在满足需求或可通过官方组合方式满足需求的组件时优先采用。只有综合端全局组件/Hooks 和 Element Plus 均确实无法满足时，才允许自行编写 UI 组件，并在职责清单和交付中记录已核对的候选组件及不适用原因；不得仅凭记忆、个人偏好或样式差异跳过官方组件。地图、视频等专项能力仍按对应专项规范选型，不适用本通用顺序。
6. **实现接口**：统一走 `/@/utils/request`；函数命名先遵循当前业务域相邻 API 和最新版规范，不强行套用历史命名。
7. **实现页面状态**：按适用性覆盖加载态、空态、错误态、权限、校验、防重复提交和资源清理。
8. **适配模块联邦**：涉及 remote、expose、manifest、远程菜单、shared、运行时入口或模块联邦配置时，先检查 `aura-module-federation-check` 是否可用；缺失时提示用户安装。可用后先建立基线，由本技能完成实现后再次复检。远程页面不得依赖提供方 `main.ts` 的全局注册副作用；按需注册、组件库 Resolver 或自动导入组件由提供方优先通过编译期 Resolver 注入组件代码与 `sideEffects` 样式，宿主不得承担提供方组件库的安装和解析职责。必须从构建产物核验对应 JS import 与 CSS 依赖，并分别验证独立运行和远程加载，控制台不得出现 `Failed to resolve component`，组件容器尺寸和样式必须正常。Resolver 无法覆盖时才显式导入组件及配套样式，禁止只导入组件 JS。
9. **适配资源和样式**：import 资源使用 `getStaticResourceUrl`，public 资源使用 `getPublicResourceUrl`；使用主题变量并保证 Flex 高度链路；按 `$frontend-design` 产出的视觉令牌统一颜色、字体、间距、圆角、层级和动效。
10. **同步注释**：实现前按所选页面模式列出注释锚点，编码时同步生成和更新有价值的简体中文注释，禁止交付前集中补泛化注释。
11. **联调与验证**：新业务菜单权限流程命中时，先主动询问是否同步创建/更新正式菜单和按钮权限，以及是否需要配置远程菜单；用户选择同步后再收集目标环境、运行时凭据、租户和父菜单定位信息，并在实际写入前再次确认。条件齐全且确认后，按参考流程调用管理端 API 幂等写入并复核；选择不同步或信息不全时不得外部写入，仅交付配置清单。不提供远程菜单时，撤销本次业务页面新增的远程暴露项（包括 `src/hooks/moduleFederation.ts` 中对应的业务 expose 配置及相关远程菜单字段），但保留框架标准 expose；页面仍因其他消费方/提供方关系需要模块联邦时，保留其必要配置。是否执行独立/远程运行验证按最终模块联邦形态决定。

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

### 命名强制约束

- 项目、目录、Vue/CSS/SCSS/HTML 和静态资源文件使用小写 `kebab-case`；JavaScript/TypeScript 模块文件使用 `camelCase`，例如 `mapConfig.ts`、`coordinateTransform.ts`。
- 组合式 Hook 文件使用 `useXxx.ts`，导出函数使用 `useXxx`；Vue 组件名使用 PascalCase，组件文件仍使用 `kebab-case`。
- 函数、方法、变量、参数和对象成员使用 lowerCamelCase；常量使用 UPPER_SNAKE_CASE；类型、接口、枚举和类使用 PascalCase。
- CSS/SCSS 类名使用小写 `kebab-case`，组件样式优先采用 BEM（`block__element--modifier`）；避免标签、ID 和全局通配符选择器。
- 函数名必须包含动作和业务对象语义，禁止使用 `save`、`query`、`data1`、`useData` 等无法表达职责的过泛名称。
- 新增命名必须使用正确英文单词，禁止拼音、中文、无意义缩写和大小写混用；已有文件不因本规则批量重命名。

- 使用 Vue 3、TypeScript 和 `<script setup>`，具体版本以当前项目和最新版总览为准。
- 路由页必须保持单一真实元素根节点；根元素统一使用 `class="layout-padding"`，业务区域置于 `class="layout-padding-auto layout-padding-view"`，Dialog、Drawer 等弹窗可与业务区域并列置于根节点下，以兼容框架的 Transition 和运行时指令。
- 业务路由入口保留在业务目录的 `index.vue`。凡由该页面引入的私有页面组件，包括表单、详情、弹窗、抽屉、面板和嵌套业务视图，必须放入同路径的 `components/` 目录，禁止与 `index.vue` 并列；确需跨业务复用时才放入 `src/components`。
- 同一路由页出现两个及以上业务 Dialog/Drawer，或单个弹窗同时包含独立列表、表单、请求与提交状态时，编码前必须拆为页面私有组件；父页通过 `ref + defineExpose` 或 Props/Emits 编排。只有字段少、无独立请求、无复用价值的单一轻量弹窗可以内联，并在职责清单中记录理由。
- 仅供弹窗使用的详情、候选项、字典项和业务列表由弹窗持有，并在公开的 `openDialog/openDrawer/open` 流程中按需加载；禁止父页面、弹窗挂载阶段或 `immediate` 监听提前请求。父页面只传入记录 ID、已选 ID 等本次操作上下文；只读加载失败使用弹窗局部错误态和重试，不弹全局消息。
- 顶部或摘要工具栏已有新增等主操作时，空态不得重复放置相同按钮；只保留说明、重试、授权或当前状态独有的恢复操作。
- 父子组件自定义事件及任何需要访问组件 ref 的模板事件必须绑定脚本中已定义的具名方法，例如 `@edit="handleEdit"`；禁止直接绑定或调用组件 ref 成员，也禁止用内联箭头函数访问 ref。普通业务方法可按需接收当前行等上下文；需要调用子组件公开方法时，由具名方法通过 `ref.value?.method(...)` 安全访问，避免挂载前在渲染阶段读取 `undefined`。
- 模板使用全局或局部组件时，`<script setup>` 中的 `ref/reactive/computed/shallowRef/shallowReactive` 数据绑定不得与任何组件标签同名或规范化后同名，否则 Vue 会把响应式数据当作组件解析。数据状态统一使用带业务语义的 `xxxState`、`xxxData` 或放入所属 `state.xxx`；交付前必须运行项目规则扫描检查此类遮蔽。
- 项目内部路径使用 `/@/`，避免跨层级相对路径。
- 列表页按真实 `useTable(state)` 签名传入响应式状态，并使用返回的 `tableStyle`、分页、排序和下载能力；不要从返回值中解构不存在的 `state`。
- 常规 CRUD 明确要求表格占满剩余高度时，页面容器建立纵向 Flex 高度链路，滚动父级和表格区写 `min-height: 0`，表格使用 `class="el-table--fit"` 与 `flex: 1`；不得使用 `100vh` 或固定像素表格高度。
- 普通内容区域需要滚动时必须使用 Element Plus `el-scrollbar`，不得用 `overflow: auto/scroll`、`overflow-y-auto`、`overflow-auto` 等原生 CSS/Tailwind 滚动实现；查询区、工具栏和分页置于滚动区域外。`el-table`、`el-tree`、`el-select` 等已有内置滚动能力的 Element Plus 组件优先使用其公开高度、最大高度或组件自身滚动能力，不额外套 `el-scrollbar`。
- v-loading 覆盖的区域如果自身或实际滚动容器可能滚动，loading 期间必须锁定该滚动容器（overflow: hidden 或等效状态类），loading 结束后恢复；局部表格、树、弹窗和地图只锁定其实际覆盖区域，不得误锁整页。
- 新建或修改普通 `el-select` 默认添加 `filterable`；仅用户明确关闭、组件不兼容或需求明确禁止搜索时例外，并说明原因。
- 权限按钮遵循项目 `v-auth` 约定；表单提交前校验，提交期间禁用，成功后再关闭和刷新。
- 所有业务表单必须从 `/@/hooks/form` 使用 `useForm`；通过 `validateForm` 校验，通过 `resetForm` 重置字段，通过 `clearFormValidate` 清理复用弹窗的历史校验状态。业务页面禁止直接调用表单实例的 `validate/resetFields/clearValidate`，也不得重复编写对应逻辑。
- import 图片、SVG、视频等先经 `getStaticResourceUrl`；Worker、decoder 等 public 资源经 `getPublicResourceUrl`。
- 业务开发需要颜色时，按 `--el-*` → `--next-*` → `--fxft-*` 的顺序从现有主题变量中选用；变量含义和场景以 `knowledge/PIGX前端开发规范/样式布局与静态资源规范.md` 为准。
- 除非用户明确要求，业务开发不得新增或修改 `.el-*`、`:deep(.el-*)`、`--el-*` 重写及全局 Element Plus 样式覆盖；正常使用 Element Plus 组件公开 props 不受影响。
- 不直接创建 axios 实例，不自行处理认证失效，不硬编码域名、IP、Token、Cookie、密码或部署前缀。
- Element Plus 保持本地依赖，不加入 Module Federation shared；Vue、Vue Router、Vue I18n、Pinia 按最新版模块联邦规范共享。
- 地图使用 `FxftMap`；单路和多路视频使用 `FxftVideoPlayer`、`FxftMultiVideoPlayer`，不得重复封装底层 SDK。
- 中文文档、注释、提示和新增文本文件使用 UTF-8 无 BOM。

## 正式菜单与按钮权限

新开发业务仅在新增正式业务页面、菜单入口或页面操作按钮时自动进入此流程；组件修复、隐藏页、纯后端改动和无正式入口的页面私有组件不触发。流程命中后应主动询问是否同步创建/更新菜单和按钮权限，并询问是否需要配置远程菜单，不要求用户事先主动提出该要求。

1. 从真实页面实现、路由/组件路径和 `v-auth` 生成页面菜单及按钮权限清单。先按权限编码去重，并为每个编码记录全部源码引用位置；同一编码在多个按钮出现时只生成一条后台按钮权限。用户明确指定的页面或按钮权限编码必须原样采用；未指定时，默认按“业务标识 + 功能动作”生成，例如项目采用下划线时使用 `device_add`、`device_edit`、`device_delete`。业务标识来自真实业务对象/页面资源，动作对应按钮实际功能，并对齐相邻模块的大小写、分隔符和动作词；不得只生成 `add/edit/delete` 或凭空增加前缀，并在清单中记录生成依据。
2. 权限查重必须覆盖四个阶段：生成前识别每个编码所属的真实业务页面/资源；候选清单检查是否有两个不同业务使用同一编码；每次 API 写入前查询目标租户与目标系统完整菜单树，并比较父菜单、路由/组件和业务语义；写入后再次确认没有跨业务同码占用。同一业务中多处相同 `v-auth` 是合法复用，只对应一条后台权限，不得误报；相同编码落在不同业务、父级、类型或路由资源时才停止该项，不得新增、静默改挂载或自动追加数字/随机后缀。页面菜单先创建或更新，每个唯一按钮权限以真实页面菜单 ID 为父级。
3. 用户在主动询问后确认同步创建/更新，并提供目标环境、管理端 Token、租户和父菜单定位信息时，按参考流程在写入前再次确认，随后调用真实项目 API 幂等创建/更新并重新查询核验。
4. 用户选择不同步，或任一环境、凭据、租户、父菜单信息缺失时不得外部写入；交付中列出缺少项并保留可执行配置清单。凭据只在运行时使用，绝不落盘、写入源码、Markdown 或日志。

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
2. Prettier 自动格式化和 `git diff --check`。
3. 当前项目可用的 build/typecheck 与 lint 命令。
4. `scripts/check-project-rules.ps1 -ProjectPath <项目路径> -StrictUiContracts`，检查消息 API、路径别名、高风险违规、注释覆盖、字典契约、i18n 与 placeholder；错误必须先修复。
5. 对应最新版页面模式和 `knowledge/PIGX前端开发规范/开发检查清单.md`。
6. 使用 Codex 内置浏览器验证核心流程；有可访问原型时同步对照，模块联邦任务同时验证独立运行和远程运行。

## 交付格式

1. **完成内容**：新增和修改文件。
2. **规范依据**：读取的最新版正式规范、页面模式和补充资料。
3. **项目适配**：真实源码、类型、Hook、组件、路由、模块联邦和命名的映射。
4. **消息检查**：确认只使用统一消息 Hook，并报告扫描结果。
5. **注释验收**：按页面模式逐项列出注释位置、覆盖的 Why/契约/边界，以及已处理或不适用的告警。
6. **联调与验证**：接口、构建、lint、Codex 内置浏览器及独立/远程运行结果；包含原型对照的一致项、差异项和用户待决策项。
7. **剩余风险**：未验证的接口、权限、远程环境、依赖或部署项。
