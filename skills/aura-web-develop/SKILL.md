---
name: aura-web-develop
description: 按 PIGX 综合端规范开发或修改 Vue 3 + Vite + TypeScript 业务，补齐代码注释与业务说明，完成开发自检、整改和测试后交付开发审查报告；也适用于指定旧业务的注释与逻辑梳理。
---

# Aura PIGX 综合端业务开发

当前版本：`1.4.4`（2026-10-26）。

## 执行入口

1. 首次命中时简要说明本技能负责本次 PIGX 业务实现；已有明确需求时直接推进。用户询问用法、帮助或示例时才读取 [USAGE.md](USAGE.md)。
2. 先核对任务相关的项目源码、接口类型、依赖及相邻实现，再按下表读取命中的资料。多场景任务合并去重；未命中的资料不读，同一会话已读且未变化的资料不重复读。
3. 规范优先级：用户明确要求 → 当前项目真实接口、类型与依赖 → [最新版正式规范](knowledge/PIGX前端开发规范/README.md) → 本技能补充规则 → 历史写法。首次接触项目或涉及架构时读取正式规范总览；局部修改直接读取相关专项规范，不固定加载整套文档。
4. 本文只维护入口、底线和索引；细则在下列对应文档单处维护。命中场景即必须遵循该文档，不因按需加载而降低约束。正式规范目录的阅读顺序是导航，不要求每个任务全读。

## 始终遵守

- 仅面向框架 1.2.0 与精确版本 `@fxft/aura-web-kit@1.9.0`（声明、锁文件与安装一致），不保留旧实现与入口兼容。公共工具、Hook、运行时和构建修复先查公开能力；通用实现进入公共包，项目只绑定实例、环境和资源。公共 UI 使用 `@fxft/aura-ui` 的 Aura 前缀组件。
- 只处理授权范围，保留工作区已有改动；接口、Hook、组件和权限以真实契约为准，不虚构。用户任务优先，先区分“新开发/功能修改”与“纯注释/业务说明整理”。纯整理只允许修改注释和说明文档，保持可执行代码与行为；不得修改 DOM 属性、组件、import、状态、接口、控制流、依赖或配置，包括不得借规范整改增加重试、useForm、竞态处理或替换字典组件。发现既有 FE 功能偏差仅记录原有问题、证据和建议，不自动修复，也不因此停止其余可读性整理；无需逐项反复询问授权。新开发/功能修改在用户原授权内整改。
- 请求使用 `/@/config/aura/request`；消息使用 `/@/config/aura/index`；表单生命周期使用 `useForm`。不复制框架底层实现。
- 需要已有对象完整信息或当前状态时按 ID 查询详情，入口快照不能作为详情；日期时间处理必须使用 `dayjs`；用户可见文案走 i18n。具体边界按下表读取。
- 外部技能调用前检查当前可用列表；缺失按 [依赖流程](references/skill-dependency-workflow.md) 处理，未经用户明确授权不得安装。
- 报告实际完成与未验证项。状态问答、首次构建失败或走查结论后继续剩余已授权工作，不把中间结果当成交付完成。
- 所有业务修改（包括更新既有业务）均必须读取[注释规范](references/code-comment-guidelines.md)，先从实际源码提取业务对象覆盖清单，再逐项覆盖变量/状态、模板区块与业务元素、业务组件实例、方法及执行步骤；不能仅补新方法或文件头。新开发、修改业务及旧代码注释/逻辑梳理均自动执行[开发闭环](references/development-review-workflow.md)：实现业务 → 补齐注释和业务说明 → `aura-web-review` 的 `development-self-check` → 按记录整改、复查与必要测试 → 按任务类型完成必需项后交付：功能任务交开发审查报告；纯整理仅以可读性及行为保持验收，交限定范围的注释/说明整理审阅报告，并列出既有功能偏差，不宣称整体 FE 合规。每块通过后继续已授权工作，整体再验证跨块衔接。

## 按场景读取

| 命中场景 | 必须读取的资料 |
| --- | --- |
| 公共工具/Hook 选型、1.2.0 迁移、自动导入或公共 TS 修改 | [aura-web-kit 清单与接入](knowledge/PIGX前端开发规范/aura-web-kit能力清单与接入规范.md)，先核对已安装版本 exports；只面向 1.2.0，不保留旧实现与旧路径兼容 |
| 首次接触项目、架构或框架边界 | [总览](knowledge/PIGX前端开发规范/PIGX前端开发总览.md)、[开发边界](knowledge/PIGX前端开发规范/开发边界说明.md) |
| 修改业务代码、命名、组件职责或布局 | [业务实现约束](references/implementation-rules.md)；新建模块/重构另读 [工程规范](knowledge/PIGX前端开发规范/工程与代码生成规范.md) |
| 查看、编辑、复制、分配等需要已有对象数据 | [已有业务对象加载](references/business-object-loading.md)，适用页面、Tab、面板、抽屉和弹窗 |
| 日期时间解析、格式化、比较、运算、时间戳或时区 | [dayjs 时间处理](references/date-time-guidelines.md) |
| 字段、筛选、表格、表单、字典或用户可见文案 | [字典、i18n 与占位契约](references/ui-data-contracts.md)；涉及三字典组件 Props、选项、空值或接入时先读 [aura-ui 组件库入口](knowledge/PIGX前端开发规范/aura-ui组件库/README.md)，再仅加载实际使用组件的 DictTag.md / DictText.md / DictSelect.md |
| 消息、确认框、请求失败反馈 | [消息反馈](references/message-feedback-guidelines.md) |
| 表单校验、重置、列表 Hook | [Hooks 契约](recipes/hooks-standards.md) |
| 组件选型或远程组件解析与样式 | [组件选型](references/component-selection.md)、[组件复用规范](knowledge/PIGX前端开发规范/组件复用与公司基础组件库规范.md) |
| 页面布局、主题或静态资源 | [样式与资源](knowledge/PIGX前端开发规范/样式布局与静态资源规范.md) |
| 新增或改造用户可见页面、CRUD、看板、地图/视频容器、跨页面视觉组件 | [视觉协作](references/frontend-design-workflow.md)，检查并调用 `frontend-design` |
| 路由、菜单、隐藏页 | [路由规范](knowledge/PIGX前端开发规范/路由与菜单规范.md) |
| 新增正式业务页面、菜单入口或操作按钮；管理端菜单权限同步 | [菜单权限流程](references/admin-menu-permission-workflow.md)，主动确认是否同步及是否配置远程菜单；外部写入须有授权 |
| remote、expose、manifest、shared 或模块联邦运行时 | [模块联邦规范](knowledge/PIGX前端开发规范/模块联邦开发技术规范.md)、[组件选型](references/component-selection.md)；使用 `aura-module-federation-check` 做改前基线与改后复检 |
| 2D 地图 / 视频 | 分别读取 [地图规范](knowledge/PIGX前端开发规范/2D地图开发规范.md) / [视频规范](knowledge/PIGX前端开发规范/视频开发规范.md)，检查并调用 `fmap-2d` / `fxft-video` |
| 公司组件库依赖安装 | [下载与权限](knowledge/PIGX前端开发规范/公司组件库下载说明/README.md) |
| API/Apifox / Figma | 分别读取 [Apifox 流程](recipes/apifox-workflow.md) 与 [MCP 指南](references/apifox-mcp-guide.md) / [Figma 流程](references/figma-design-workflow.md) |
| 新开发、修改业务、补旧代码注释或业务逻辑说明 | [注释规范与三类可复制模板](references/code-comment-guidelines.md)、[开发闭环与文档交付](references/development-review-workflow.md) |
| 可见页面/交互改造验收，或用户提供可访问原型 | [Codex 内置浏览器走查](references/codex-browser-review-workflow.md)；按当前工具能力连接，不以旧技能名缺失判定不可用；原型在编码前建立对照，完成后复核 |

## 页面模式

新建或调整页面结构时选择实际命中的模式，只读取对应文档：

[查询表格](knowledge/PIGX前端开发规范/页面模式/查询表格页.md) · [查询卡片](knowledge/PIGX前端开发规范/页面模式/查询卡片页.md) · [左树右表](knowledge/PIGX前端开发规范/页面模式/左树右表页.md) · [弹窗表单](knowledge/PIGX前端开发规范/页面模式/弹窗表单.md) · [详情与抽屉](knowledge/PIGX前端开发规范/页面模式/详情页与抽屉.md) · [看板](knowledge/PIGX前端开发规范/页面模式/看板页.md) · [Teleport 嵌套页](knowledge/PIGX前端开发规范/页面模式/Teleport嵌套页面模式.md)。

完整页面开发先明确页面、私有组件、Composable、API、类型和 i18n 职责，再按模式实现；局部修复无需重新执行整页设计。历史 `templates/` 不能覆盖正式模式。

## 验证与交付

- 修改代码后按 [格式化流程](references/prettier-formatting-workflow.md) 执行项目本地 Prettier 和 `git diff --check`。
- 按任务范围使用 [实现清单](checklists/implementation.md)、[验证清单](checklists/validation.md) 和 [正式检查清单](knowledge/PIGX前端开发规范/开发检查清单.md) 中命中的项目；完整页面开发覆盖全部适用项。
- 业务代码修改在构建前运行 `scripts/check-project-rules.ps1 -ProjectPath <项目路径> -StrictUiContracts`，处理错误，再执行项目可用 build/typecheck、lint；可见交互按浏览器流程验收，模块联邦任务验证独立和远程运行。
- 维护技能本身运行 `scripts/validate-skill.ps1`；能力清单变更时运行 `scripts/check-web-kit-catalog.ps1 -PackagePath <已安装的 aura-web-kit 包目录>`，不启动业务项目的构建或浏览器流程。
- 开发自检只读、整改由本技能负责；调用前确认实际加载的审查技能支持模式，精确入口与旧版能力缺口处理见[开发闭环](references/development-review-workflow.md)。不能以正式六文件流程代替自检。
- 交付门槛按用户任务限定：纯整理仅修改注释/文档，完成可读性和行为保持检查后可交注释/说明整理审阅报告；既有功能偏差单列、不自动修。用户明确要求全规范通过时，功能偏差阻断该合规目标并列需授权事项，继续独立整理。新开发/功能修改全部适用必需检查和测试通过后，才生成面向开发人员的报告；环境缺失、失败或证据不足记阻断，继续可独立工作，不提前输出该块最终报告。说明与图示按模块维护，报告引用说明并标记“自检通过，待人工审查”。

本轮 MF Vite 1.23.5、web-kit 1.9.0 与 TypeScript 5.9.3 配套基线及来源见 [升级来源记录](references/framework-upgrade-source.json)；按模块联邦规范接入自动预构建和 ESLint 配套配置，不沿用旧扫描插件或强制手工清单。

本次可读性与自检流程直接维护于本技能仓库，来源及未发布状态见[本地变更记录](references/readability-source.json)；不替换既有规范来源记录。

业务枚举/字典展示强制使用 `@fxft/aura-ui` 的 `AuraDictTag` / `AuraDictText`，禁止手写展示转换；选项、非展示编码判断及公开契约取证边界见[字典契约](references/ui-data-contracts.md)。
