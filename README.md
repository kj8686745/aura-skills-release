# Aura Skills Release

这是福信富通技能的统一发布仓库，正式、公开试用和内部技能共同维护；`manifest.json` 和下表通过 `visibility`、`releaseState` 标记交付范围。开发源码、未发布变更和维护资料不在此仓库中。

## 安装

安装指定技能到 Codex 的全局技能目录：

```powershell
npx skills add kj8686745/aura-skills-release --skill <技能名称> --global --yes --agent codex
```

安装全部已发布技能到 Codex：

```powershell
npx skills add kj8686745/aura-skills-release --skill '*' --global --yes --agent codex
```

更新指定的全局已安装技能：

```powershell
npx skills update <技能名称> --global --yes
```

更新全部全局已安装技能：

```powershell
npx skills update --global --yes
```

按各技能的安装来源更新，包含其他仓库的全局技能；不会额外安装尚未安装的技能。

## 技能管理

查看已安装的技能：

```powershell
npx skills list
```

删除多个技能：

```powershell
npx skills remove <技能名称> to-spec diagnosing-bugs
```

删除全局安装的技能：

```powershell
npx skills remove -g <技能名称>
```

跳过确认直接删除：

```powershell
npx skills remove -y <技能名称>
```

删除所有技能：

```powershell
npx skills remove --all
```

## 已发布技能

| 技能 | 方向 | 版本 | 交付状态 | 说明 |
| --- | --- | --- | --- | --- |
| aura-ai-workflow | 通用、AI | 0.2.1-draft | 公开试用（待行为验收） | 在研发任务中建立 AI 工作入口、管理会话与上下文，或复核 AI 输出的采纳和人工确认边界时使用；普通编码任务仍由相应研发技能承担。 |
| aura-backend-compliance-review | 前端、后端、接口、审查 | 1.31.0 | 公开试用（待行为验收） | 只读审查 AURA Java/Spring 后端变更、接口或项目的规范执行与代码质量，核对基础能力复用，交付规范、代码缺陷、公共能力提炼、优秀实践四份报告；不实施代码整改。 |
| aura-base-backend-development | 后端、开发、能力使用 | 1.33.0 | 公开试用（待行为验收） | 初始化、开发或重构 AURA Java/Spring 后端项目与业务，按需接入数据库、鉴权、文件、实时通信、调度及网关能力；不用于独立技术设计文档、项目规范审查或框架能力包建设。 |
| aura-base-interface-development | 前端、后端、接口、开发 | 1.5.2 | 正式 | 为 AURA 前后端、服务间或对外 OpenAPI 设计统一接口契约，按业务模块编写接口文档并准备联调；具体页面和服务内部实现分别交由前后端开发技能。 |
| aura-base-interface-review | 前端、后端、接口、审查 | 1.0.2 | 正式 | 审查已开发一段时间的 AURA 前后端或服务间接口，识别现状、调用方和统一契约差异，输出可执行的调整顺序与验证结论；不替代新接口设计、后端实现或真实联调。 |
| aura-base-project-engineering | 通用、工程、开发 | 1.2.2 | 正式 | 初始化或维护 AURA 项目的工程结构、模块依赖、项目文档、配置与构建入口；用于新工程、增加模块和局部工程变更，不接管业务功能、前端页面实现或项目规范审查。 |
| aura-cap-base-use | 后端、能力包、使用 | 1.0.2 | 正式 | AURA 后端业务开发需要统一响应、JSON、当前用户、权限、租户、缓存、日志审计、Feign 或文件存储等公共能力时使用；不处理公共包内部实现。 |
| aura-cap-common-business-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 后端业务应用中组合公共数据访问、基础实体、统一响应、安全上下文与本地事务入口时，按基础业务开发能力包定位接入方法和完整示例；通用分层与交付规则以基础编码规范为准。 |
| aura-cap-data-infra-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 业务服务中接入动态数据源或 Snowflake 分布式编号，或核对跨服务事务模块当前能否接入时使用；普通单库 CRUD 与本地事务不触发本技能。 |
| aura-cap-data-security-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 业务应用中处理敏感字段脱敏、XSS 内容清理、实体字段保护或 HTTP 报文加密时使用；不替代认证、授权和租户开发。 |
| aura-cap-file-realtime-use | 后端、能力包、使用 | 1.0.2 | 正式 | AURA 业务应用接入 Excel、SSE、WebSocket、Socket.IO 或组合文件任务，或核对下载任务模块是否可接入时使用；单独文件存储接入转基础通用支撑能力技能。 |
| aura-cap-job-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 业务服务中接入 XXL-JOB 执行器、开发定时任务或核对调度结果时使用；不用于普通同步接口、消息消费或文件导出。 |
| aura-cap-traffic-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 网关或业务服务中设计动态路由、网关与 Feign 灰度、Servlet/Feign 保护或网关限流时使用；不处理业务授权和普通 CRUD。 |
| aura-capability-package-build | 治理、能力包、构建 | 0.7.1 | 内部交付 | 为 AURA 的某个能力域建设或更新能力包候选；从指定版本的源码、SDK 和公开契约核实真实能力，最多形成能力说明、接入与使用手册、版本与兼容记录三份对外文档，并准备候选使用模块，供内部复核。仅用于能力包建设，不用于业务项目直接接入或宣称发布。 |
| aura-detailed-design | 通用、设计 | 0.3.2-draft | 公开试用（待行为验收） | 依据 AURA 技术详细设计规范，为影响模块、数据、状态、接口或运行边界的业务变更新建、修订或只读复核技术详细设计；不负责实现代码、替代接口文档或全项目规范审查。 |
| aura-module-federation-check | 前端、审查 | 1.1.8 | 正式 | 检查 AURA 综合端的模块联邦配置、运行时、预构建和构建产物。普通检查自动修复证据与改法明确的偏差并复检，有实际取舍时请用户决定。支持只读审计、改前基线、改后复检及对外接入说明；独立生产端、消费端仅识别类型。 |
| aura-review-skill-build | 前端、后端、治理、审查、内部构建 | 0.8.0 | 内部交付 | 为前端、后端或接口负责人建设审查技能，构建只读工作流、规则取证与规范/缺陷/公共能力/优秀实践四维报告，并验证产物；不直接承担业务项目审查或整改。 |
| aura-web-develop | 前端、开发 | 1.6.16 | 正式 | AURA 前端项目开发与编辑的规范入口。综合端新增功能、局部编辑、样式配置调整、修复及重构均须按改动执行全部适用规范并验收；框架内部修改由框架角色沿用适用条款。也支持结构咨询和纯注释整理。 |
| aura-web-project-router | 前端、路由 | 1.0.5 | 正式 | 为已知 AURA 前端项目或身份待确认的 Vue 3 + Vite 项目分流。开发、编辑、后续小改进入开发规范流程，框架内部修改按框架职责实施。按请求范围选择审查、诊断、咨询或模块联邦与 Vite 预构建专项。 |
| aura-web-review | 前端、审查 | 1.0.2 | 公开试用（待行为验收） | 只读审查 AURA Vue 3 + Vite + TypeScript 前端项目、模块或变更，支持结构与测试合理性只读咨询；限定变更默认单报告，全项目或正式审查保留六文件，开发闭环使用 development-self-check 轻量记录。不实施业务修复。 |
| fmap-2d |  | 1.0.6 | 正式 | 公司 2D 地图业务开发规范技能，指导 Agent 在 Vue 3 + Vite 项目中接入 @fxft/ui-plus，并使用 FxftMap 完成地图页面、点位聚合、轨迹回放、热力图、绘制和 GeoJSON 渲染。 |
| fxft-video |  | 2.0.6 | 正式 | 在 Vue 3 + Vite 项目中使用 @fxft/ui-plus 的 FxftWebVideo 与 FxftWebMultiVideo 实现直播、回放、点播、PTZ、分屏、拖拽、多选和通道管理。 |

发布清单见 [manifest.json](./manifest.json)。内部技能只应交给已授权的内部使用者，公开安装时按 `visibility` 选择范围。
