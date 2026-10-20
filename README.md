# Aura Skills Release

这是福信富通技能的发布仓库，包含正式及公开试用技能；公开试用仍待行为验收，可按技能名称选择安装；开发源码、未发布变更和维护资料不在此仓库中。

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
| aura-ai-workflow | 通用、AI | 0.1.0-draft | 公开试用（待行为验收） | 在研发任务中建立 AI 工作入口、管理会话与上下文，或复核 AI 输出的采纳和人工确认边界时使用；普通编码任务仍由相应研发技能承担。 |
| aura-backend-compliance-review | 前端、后端、接口、审查 | 1.1.2 | 公开试用（待行为验收） | 只读审查 AURA Java/Spring 后端项目或存量内外 API 的规范偏差，连续完成范围冻结、资产盘点、取证、逐规则判定和统一结果包；接口专项按限定范围执行，不修改业务代码。 |
| aura-base-backend-development | 后端、开发、能力使用 | 1.1.2 | 公开试用（待行为验收） | 按 AURA 规范开发或重构 Java/Spring 后端业务和内外 API，并按需接入数据库、鉴权、文件、实时通信、调度及网关等框架能力；不用于独立技术设计文档、项目规范审查或框架能力包建设。 |
| aura-base-interface-development | 前端、后端、接口、开发 | 1.0.7 | 正式 | 为 AURA 前后端、服务间或对外 OpenAPI 设计统一接口契约，按业务模块编写接口文档并准备联调；具体页面和服务内部实现分别交由前后端开发技能。 |
| aura-base-interface-review | 前端、后端、接口、审查 | 1.0.2 | 正式 | 审查已开发一段时间的 AURA 前后端或服务间接口，识别现状、调用方和统一契约差异，输出可执行的调整顺序与验证结论；不替代新接口设计、后端实现或真实联调。 |
| aura-base-project-engineering | 通用、工程、开发 | 1.0.6 | 正式 | 新建或调整 AURA 业务工程、模块结构、命名、项目文档、依赖配置、构建或版本交付时，按基础编码规范确定工程落点与交付方式；不负责专项能力实现。 |
| aura-cap-base-use | 后端、能力包、使用 | 1.0.2 | 正式 | AURA 后端业务开发需要统一响应、JSON、当前用户、权限、租户、缓存、日志审计、Feign 或文件存储等公共能力时使用；不处理公共包内部实现。 |
| aura-cap-common-business-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 后端业务应用中组合公共数据访问、基础实体、统一响应、安全上下文与本地事务入口时，按基础业务开发能力包定位接入方法和完整示例；通用分层与交付规则以基础编码规范为准。 |
| aura-cap-data-infra-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 业务服务中接入动态数据源或 Snowflake 分布式编号，或核对跨服务事务模块当前能否接入时使用；普通单库 CRUD 与本地事务不触发本技能。 |
| aura-cap-data-security-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 业务应用中处理敏感字段脱敏、XSS 内容清理、实体字段保护或 HTTP 报文加密时使用；不替代认证、授权和租户开发。 |
| aura-cap-file-realtime-use | 后端、能力包、使用 | 1.0.2 | 正式 | AURA 业务应用接入 Excel、SSE、WebSocket、Socket.IO 或组合文件任务，或核对下载任务模块是否可接入时使用；单独文件存储接入转基础通用支撑能力技能。 |
| aura-cap-job-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 业务服务中接入 XXL-JOB 执行器、开发定时任务或核对调度结果时使用；不用于普通同步接口、消息消费或文件导出。 |
| aura-cap-traffic-use | 后端、能力包、使用 | 1.0.2 | 正式 | 在 AURA 网关或业务服务中设计动态路由、网关与 Feign 灰度、Servlet/Feign 保护或网关限流时使用；不处理业务授权和普通 CRUD。 |
| aura-detailed-design | 通用、设计 | 0.1.1-draft | 公开试用（待行为验收） | 依据 AURA 技术详细设计规范，为影响模块、数据、状态、接口或运行边界的业务变更编写或复核技术详细设计；不负责直接实现代码或代替接口文档。 |
| aura-module-federation-check |  | 1.1.0 | 正式 | 自动识别 Vue 3 + Vite 项目属于 PIGX 综合端、模块联邦生产端或消费端，并检查 PIGX 综合端的模块联邦身份、依赖、Vite 配置、shared singleton、运行时外壳、i18n、样式、静态资源和构建产物。模块联邦配置由 Web 开发技能实现，本技能提供改前基线、改后复检与对外接入说明；首版生产端或消费端仅报告类型和证据。 |
| aura-web-develop |  | 1.3.0 | 正式 | 按 PIGX 模块联邦综合端规范开发和评审 Vue 3 + Vite + TypeScript 业务，涵盖 CRUD、接口、菜单权限、组件复用与模块联邦实现；适用于 aura-pigx-cli nexus 项目及其业务远程模块。 |
| aura-web-project-router |  | 1.0.3 | 正式 | 对当前框架未知的 Vue 3 + Vite 项目进行轻量只读识别，并在 PIGX 综合端开发、CRUD、路由菜单、权限、地图、视频或模块联邦配置时分流到对应技能；不实现业务，也不接管普通 Vue/Vite、React 或非 PIGX 项目。 |
| fmap-2d |  | 1.0.6 | 正式 | 公司 2D 地图业务开发规范技能，指导 Agent 在 Vue 3 + Vite 项目中接入 @fxft/ui-plus，并使用 FxftMap 完成地图页面、点位聚合、轨迹回放、热力图、绘制和 GeoJSON 渲染。 |
| fxft-video |  | 2.0.6 | 正式 | 在 Vue 3 + Vite 项目中使用 @fxft/ui-plus 的 FxftWebVideo 与 FxftWebMultiVideo 实现直播、回放、点播、PTZ、分屏、拖拽、多选和通道管理。 |

发布清单见 [manifest.json](./manifest.json)。
