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

更新已安装技能：

```powershell
npx skills update <技能名称> --global --yes
```

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
| aura-ai-workflow | 通用、AI | 0.2.0-draft | 公开试用（待行为验收） | 在研发任务中建立 AI 工作入口、管理会话与上下文，或复核 AI 输出的采纳和人工确认边界时使用；普通编码任务仍由相应研发技能承担。 |
| aura-backend-compliance-review | 前端、后端、接口、审查 | 1.21.0 | 公开试用（待行为验收） | 只读审查 AURA Java/Spring 后端变更、存量接口或全项目的规范偏差，核对基础能力复用并交付带证据的报告；变更用单报告，全项目用六文件包，不执行代码整改。 |
| aura-base-backend-development | 后端、开发、能力使用 | 1.26.0 | 公开试用（待行为验收） | 初始化、开发或重构 AURA Java/Spring 后端项目与业务，按需接入数据库、鉴权、文件、实时通信、调度及网关能力；不用于独立技术设计文档、项目规范审查或框架能力包建设。 |
| aura-base-interface-development | 前端、后端、接口、开发 | 1.4.4 | 正式 | 为 AURA 前后端、服务间或对外 OpenAPI 设计统一接口契约，按业务模块编写接口文档并准备联调；具体页面和服务内部实现分别交由前后端开发技能。 |
| aura-base-interface-review | 前端、后端、接口、审查 | 1.0.2 | 正式 | 审查已开发一段时间的 AURA 前后端或服务间接口，识别现状、调用方和统一契约差异，输出可执行的调整顺序与验证结论；不替代新接口设计、后端实现或真实联调。 |
| aura-base-project-engineering | 通用、工程、开发 | 1.1.1 | 正式 | 初始化或维护 AURA 项目的工程结构、模块依赖、项目文档、配置与构建入口；用于新工程、增加模块和局部工程变更，不接管业务功能、前端页面实现或项目规范审查。 |
| aura-cap-base-use | 后端、能力包、使用 | 1.0.2 | 正式 | AURA 后端业务开发需要统一响应、JSON、当前用户、权限、租户、缓存、日志审计、Feign 或文件存储等公共能力时使用；不处理公共包内部实现。 |
| aura-cap-common-business-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 后端业务应用中组合公共数据访问、基础实体、统一响应、安全上下文与本地事务入口时，按基础业务开发能力包定位接入方法和完整示例；通用分层与交付规则以基础编码规范为准。 |
| aura-cap-data-infra-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 业务服务中接入动态数据源或 Snowflake 分布式编号，或核对跨服务事务模块当前能否接入时使用；普通单库 CRUD 与本地事务不触发本技能。 |
| aura-cap-data-security-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 业务应用中处理敏感字段脱敏、XSS 内容清理、实体字段保护或 HTTP 报文加密时使用；不替代认证、授权和租户开发。 |
| aura-cap-file-realtime-use | 后端、能力包、使用 | 1.0.2 | 正式 | AURA 业务应用接入 Excel、SSE、WebSocket、Socket.IO 或组合文件任务，或核对下载任务模块是否可接入时使用；单独文件存储接入转基础通用支撑能力技能。 |
| aura-cap-job-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 业务服务中接入 XXL-JOB 执行器、开发定时任务或核对调度结果时使用；不用于普通同步接口、消息消费或文件导出。 |
| aura-cap-traffic-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 网关或业务服务中设计动态路由、网关与 Feign 灰度、Servlet/Feign 保护或网关限流时使用；不处理业务授权和普通 CRUD。 |
| aura-capability-package-build | 治理、能力包、构建 | 0.7.0 | 内部交付 | 为 AURA 的某个能力域建设或更新能力包候选；从指定版本的源码、SDK 和公开契约核实真实能力，最多形成能力说明、接入与使用手册、版本与兼容记录三份对外文档，并准备候选使用模块，供内部复核。仅用于能力包建设，不用于业务项目直接接入或宣称发布。 |
| aura-detailed-design | 通用、设计 | 0.2.0-draft | 公开试用（待行为验收） | 依据 AURA 技术详细设计规范，为影响模块、数据、状态、接口或运行边界的业务变更新建、修订或只读复核技术详细设计；不负责实现代码、替代接口文档或全项目规范审查。 |
| aura-module-federation-check | 前端、审查 | 1.1.6 | 正式 | 自动识别 Vue 3 + Vite 项目属于 PIGX 综合端、模块联邦生产端或消费端，并检查 PIGX 综合端的模块联邦身份、依赖、Vite 配置、shared singleton、运行时外壳、i18n、样式、静态资源和构建产物。模块联邦配置由 Web 开发技能实现，本技能提供改前基线、改后复检与对外接入说明；首版生产端或消费端仅报告类型和证据。 |
| aura-review-skill-build | 前端、后端、治理、审查、内部构建 | 0.5.1 | 内部交付 | 为前端、后端或接口负责人开发和优化规范审查技能，构建规则路由、只读审查工作流与统一报告模板，并验证生成技能的结果包；不直接承担业务项目审查或代码整改。 |
| aura-web-develop | 前端、开发 | 1.5.0 | 正式 | 按 PIGX 综合端规范开发或修改 Vue 3 + Vite + TypeScript 业务，补齐代码注释与业务说明；功能开发完成必要验收和自检后交付开发记录或报告，纯注释/说明整理默认直接交付。 |
| aura-web-project-router | 前端、路由 | 1.0.4 | 正式 | 对框架未知的 Vue 3 + Vite 项目进行只读识别，为 Aura/PIGX 业务开发、前端规范审查、地图视频和模块联邦任务分流；不实现业务，不接管普通 Vue/Vite 或 React 项目。 |
| aura-web-review | 前端、审查 | 0.3.0 | 公开试用（待行为验收） | 只读审查 AURA/PIGX Vue 3 + Vite + TypeScript 前端项目、模块或变更；限定变更默认单报告，全项目或正式审查保留六文件，开发闭环使用 development-self-check 轻量记录。不实施业务修复。 |
| fmap-2d |  | 1.0.6 | 正式 | 公司 2D 地图业务开发规范技能，指导 Agent 在 Vue 3 + Vite 项目中接入 @fxft/ui-plus，并使用 FxftMap 完成地图页面、点位聚合、轨迹回放、热力图、绘制和 GeoJSON 渲染。 |
| fxft-video |  | 2.0.6 | 正式 | 在 Vue 3 + Vite 项目中使用 @fxft/ui-plus 的 FxftWebVideo 与 FxftWebMultiVideo 实现直播、回放、点播、PTZ、分屏、拖拽、多选和通道管理。 |

发布清单见 [manifest.json](./manifest.json)。内部技能只应交给已授权的内部使用者，公开安装时按 `visibility` 选择范围。
