---
name: aura-web-develop
description: 按 PIGX 模块联邦综合端规范开发和评审 Vue 3 + Vite + TypeScript 业务，涵盖 CRUD、接口、菜单权限、组件复用与模块联邦实现；适用于 aura-pigx-cli nexus 项目及其业务远程模块。
---

# Aura PIGX 综合端业务开发

当前版本：`1.2.28`（2026-10-08）。

## 执行入口

1. 首次命中时简要说明本技能负责本次 PIGX 业务实现；已有明确需求时直接推进。用户询问用法、帮助或示例时才读取 [USAGE.md](USAGE.md)。
2. 先核对任务相关的项目源码、接口类型、依赖及相邻实现，再按下表读取命中的资料。多场景任务合并去重；未命中的资料不读，同一会话已读且未变化的资料不重复读。
3. 规范优先级：用户明确要求 → 当前项目真实接口、类型与依赖 → [最新版正式规范](knowledge/PIGX前端开发规范/README.md) → 本技能补充规则 → 历史写法。首次接触项目或涉及架构时读取正式规范总览；局部修改直接读取相关专项规范，不固定加载整套文档。
4. 本文只维护入口、底线和索引；细则在下列对应文档单处维护。命中场景即必须遵循该文档，不因按需加载而降低约束。正式规范目录的阅读顺序是导航，不要求每个任务全读。

## 始终遵守

- 只处理授权范围，保留工作区已有改动；接口、Hook、组件和权限以真实契约为准，不虚构。
- 请求使用 `/@/utils/request`；消息使用 `/@/hooks/message`；表单生命周期使用 `useForm`。不复制框架底层实现。
- 需要已有对象完整信息或当前状态时按 ID 查询详情，入口快照不能作为详情；日期时间处理必须使用 `dayjs`；用户可见文案走 i18n。具体边界按下表读取。
- 外部技能调用前检查当前可用列表；缺失按 [依赖流程](references/skill-dependency-workflow.md) 处理，未经用户明确授权不得安装。
- 报告实际完成与未验证项。状态问答、首次构建失败或走查结论后继续剩余已授权工作，不把中间结果当成交付完成。

## 按场景读取

| 命中场景 | 必须读取的资料 |
| --- | --- |
| 首次接触项目、架构或框架边界 | [总览](knowledge/PIGX前端开发规范/PIGX前端开发总览.md)、[开发边界](knowledge/PIGX前端开发规范/开发边界说明.md) |
| 修改业务代码、命名、组件职责或布局 | [业务实现约束](references/implementation-rules.md)；新建模块/重构另读 [工程规范](knowledge/PIGX前端开发规范/工程与代码生成规范.md) |
| 查看、编辑、复制、分配等需要已有对象数据 | [已有业务对象加载](references/business-object-loading.md)，适用页面、Tab、面板、抽屉和弹窗 |
| 日期时间解析、格式化、比较、运算、时间戳或时区 | [dayjs 时间处理](references/date-time-guidelines.md) |
| 字段、筛选、表格、表单、字典或用户可见文案 | [字典、i18n 与占位契约](references/ui-data-contracts.md) |
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
| 新页面、复杂组件、接口契约或副作用注释 | [注释规范](references/code-comment-guidelines.md) |
| 可见页面/交互改造验收，或用户提供可访问原型 | [Codex 内置浏览器走查](references/codex-browser-review-workflow.md)；按当前工具能力连接，不以旧技能名缺失判定不可用；原型在编码前建立对照，完成后复核 |

## 页面模式

新建或调整页面结构时选择实际命中的模式，只读取对应文档：

[查询表格](knowledge/PIGX前端开发规范/页面模式/查询表格页.md) · [查询卡片](knowledge/PIGX前端开发规范/页面模式/查询卡片页.md) · [左树右表](knowledge/PIGX前端开发规范/页面模式/左树右表页.md) · [弹窗表单](knowledge/PIGX前端开发规范/页面模式/弹窗表单.md) · [详情与抽屉](knowledge/PIGX前端开发规范/页面模式/详情页与抽屉.md) · [看板](knowledge/PIGX前端开发规范/页面模式/看板页.md) · [Teleport 嵌套页](knowledge/PIGX前端开发规范/页面模式/Teleport嵌套页面模式.md)。

完整页面开发先明确页面、私有组件、Composable、API、类型和 i18n 职责，再按模式实现；局部修复无需重新执行整页设计。历史 `templates/` 不能覆盖正式模式。

## 验证与交付

- 修改代码后按 [格式化流程](references/prettier-formatting-workflow.md) 执行项目本地 Prettier 和 `git diff --check`。
- 按任务范围使用 [实现清单](checklists/implementation.md)、[验证清单](checklists/validation.md) 和 [正式检查清单](knowledge/PIGX前端开发规范/开发检查清单.md) 中命中的项目；完整页面开发覆盖全部适用项。
- 业务代码修改在构建前运行 `scripts/check-project-rules.ps1 -ProjectPath <项目路径> -StrictUiContracts`，处理错误，再执行项目可用 build/typecheck、lint；可见交互按浏览器流程验收，模块联邦任务验证独立和远程运行。
- 维护技能本身运行 `scripts/validate-skill.ps1`，不启动业务项目的构建或浏览器流程。
- 交付说明改动、验证结果、未验证项及待决策内容；详细证据按需要引用，不机械输出空栏目。
