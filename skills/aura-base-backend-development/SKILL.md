---
name: aura-base-backend-development
description: "初始化、开发或重构 AURA Java/Spring 后端项目与业务，按需接入数据库、鉴权、文件、实时通信、调度及网关能力；不用于独立技术设计文档、项目规范审查或框架能力包建设。"
---

# AURA 后端开发

负责需求到后端实现、自测和交付的闭环。版本见 `VERSION`，规范和能力来源见[来源记录](references/source.json)。使用方法见 [USAGE.md](USAGE.md)。

数据库设计、Entity、Mapper、SQL、迁移和事务属于本后端开发技能的数据库模块，不是独立安装技能。使用者只调用 `$aura-base-backend-development`，由任务路由按需读取数据库规范、模板和脚本；数据基础设施能力包仅作为需要时读取的能力资料，不改变数据库模块的归属。

普通业务开发只核对 `VERSION` 与项目依赖，不全文读取来源记录、规范矩阵或脚本实现；只有需要追溯时才检索 `source.json` 的顶层元数据和命中文档条目。

## 上下文预算

默认只读取本技能、一个任务路由和一个命中的规范/正反例；不加载 `source.json` 全文、完整规范矩阵、全部能力入口或审查/接口技能。详细 JSON 先写临时目录（仅支持的脚本使用 `-OutputPath`，其他用 `-Json` 重定向），再用同目录的 `select-json-summary.ps1` 只提取计数与命中项，不把完整 JSON 打入会话。普通 CRUD 不加载接口技能；只有接口契约变化时才组合接口技能，已读条款不重复装载。

## 选路

先确认需求、项目依赖和已有契约；只读取当前任务命中的正文和正反例。本技能是通用后端开发入口；若同时发现旧 `aura-backend-development`，本次采用本包依据，不叠加旧目录规则，不自动卸载或改写安装配置。

| 任务 | 直接入口 |
| --- | --- |
| CRUD、业务动作或数据处理 | [后端入口与模型](references/standards/01-基础编码规范/03-后端基础编码规范/01-代码组织与接口入口.md)，再按[基础业务路由](references/capabilities/01-基础业务/references/任务路由.md)选择 Service、Mapper、实体与事务的真实入口 |
| 数据库操作、Mapper、SQL 或事务 | [数据库操作与事务路由](references/数据库操作与事务路由.md)；分页关联、索引及存量迁移按[数据库操作模板](references/数据库操作模板.md)进入查询与结构演进，不用普通表生成器覆盖已有模块 |
| 缓存读取、回源、失效或一致性 | 先按 `AURA-BASE-DATA-018～020` 判断收益和场景边界，再读[缓存操作模板](references/缓存操作模板.md)声明键、TTL、事实来源和失效策略 |
| 文件上传下载、导入导出或批处理 | 从[文件与批处理开发](references/文件与批处理开发.md)第一节选场景，只读对应流程；复用文件服务/Excel入口，明确规模、解析错误、提交策略和结果权限 |
| 新建或初始化后端项目 | [后端项目初始化](references/后端项目初始化.md)；同时按命中项读取工程结构、项目文档、依赖配置、环境启动和构建交付规范 |
| 首次接入已有后端项目、接手陌生模块或改码前快速研读 | 按[后端项目研读](references/后端项目研读.md)先用脚本定位，再沿真实调用链整理功能、类职责和关键流程；接手说明写入既有模块 docs，不以原始 JSON 代替人工说明，不替代规范审查 |
| 为已有后端项目补充模块、类或关键逻辑注释 | 按[注释增强模式](references/后端项目研读.md#注释增强模式)核对真实逻辑并写回源码；批量插入可用 `apply-backend-comment-plan.ps1`，已有注释不重复插入 |
| 配置密码、Token、密钥或外部凭据 | 按任务路由读取 `AURA-BASE-CONF-001`、`AURA-BASE-CONF-010`；优先接入外部密钥服务，不在同一交付边界保存密文与解密密钥 |
| 存量改造、异常或性能修复 | 先限定受影响调用链；从[编码任务路由](references/任务路由.md)选命中条目，不先做全项目审查 |
| 新增或变更 HTTP/API 契约 | 先读[API 边界与网关路由](references/API边界与网关路由.md)，再读[接口规范](references/standards/01-基础编码规范/05-接口规范体系/01-接口规范.md)和[模块文档模板](references/standards/01-基础编码规范/05-接口规范体系/03-接口文档模板.md)；对外 API 另核对 `AURA-BASE-API-026` |
| 接入框架能力 | [能力使用索引](references/能力使用索引.md)选中一个模块；基础业务与公共支撑有对应功能时优先复用，其余模块按需 |

接口路径、参数、响应、错误或权限契约变化时，默认同步模块 `docs` 下已有接口文档；没有时创建并纳入项目文档入口。同一模块的接口连续维护，不按接口拆文件；纯内部实现变化不机械补文档。接口技能可用时组合处理，否则使用本包规范、模板和脚本，不自动安装其他技能。

新建后端项目时，本技能负责后端根入口、构建定义、源码/资源目录、启动入口、根 README/docs 入口和基础能力接入；不创建前端工程或未来功能的空目录。完整前后端工程初始化仍组合 `aura-base-project-engineering`，不重复生成其工程部分。

## 脚本辅助

在技能目录执行以下命令（PowerShell 7；项目路径和模块按实际替换）：

```powershell
./scripts/inspect-backend-project.ps1 -ProjectPath <项目根> -ModulePath <业务模块>
./scripts/check-backend-rules.ps1 -ProjectPath <项目根> -ModulePath <业务模块>
./scripts/check-backend-project-init.ps1 -ProjectPath <项目根> -ModulePath <后端模块> -IncludeProjectEntry -Json
./scripts/prepare-backend-project.ps1 -ProjectPath <项目根> -ModulePath <后端模块> -BuildSystem Maven -PackageName <Java包名> -Mode Plan
./scripts/prepare-database-module.ps1 -ProjectPath <项目根> -ModulePath <业务模块> -PackageName <Java包名> -EntityName <实体名> -TableName <表名> -FieldJson <字段JSON> -EntityMode Standalone -Mode Plan
# 已明确简单等值查询时再追加：-QueryJson <查询JSON>
./scripts/check-database-module.ps1 -ProjectPath <项目根> -ModulePath <业务模块> -OutputPath <临时目录>/database.json -Json
./scripts/inspect-database-changes.ps1 -ProjectPath <项目根> -FilePath @('<本次Mapper.xml>','<本次迁移.sql>') -OutputPath 'docs/临时验证物料/数据库开发/查询迁移候选.json' -Json
./scripts/prepare-cache-module.ps1 -ProjectPath <项目根> -ModulePath <业务模块> -PackageName <Java包名> -CacheClass <缓存契约类名> -CacheJson <缓存JSON> -Mode Plan
./scripts/test-backend-startup.ps1 # 仅在隔离样本或明确授权的初始化项目上执行启动探针
./scripts/test-backend-web-startup.ps1 -ProjectPath <项目根> -ModulePath <后端模块> # 仅在明确需要 Web 服务且项目已 Apply 后执行 HTTP 探针
```

首次进入模块，在改码前用前者盘点构建、依赖、源码入口、文档与直接接口；同版本、同范围的已有有效盘点可复用，不每轮重跑。实现后用后者收集本次范围的静态候选。`ModulePath` 只接收目录，单文件改动选其所属目录并从结果筛选该文件。接口文档同步再执行随包 `inventory-api-contracts.ps1`、`check-api-document.ps1`，需要代码返回模型字段候选时追加 `-IncludeResponseFields`，请求体字段候选时追加 `-IncludeRequestFields`；参数与边界见 [USAGE.md](USAGE.md)。先看摘要；较大模块写临时 JSON 后按字段筛选，不全文读取结果或脚本。`reviewFocus` 只是范围内的选读线索，须与实际差异核对；非 HTTP 范围的 `api.status=not-triggered` 不等于证明项目没有接口。

需要从 JSON 结果继续定位时，优先使用 `select-json-summary.ps1 -InputPath '<临时 JSON>' -PathFilter '<模块或文件>' -RuleId '<规则>' -ApiPath '<接口路径>'`；字段候选默认关闭，仅在当前契约核对需要时显式打开。

退出 `0` 仅表示请求的静态盘点完成；`1` 为输入或执行错误；`2` 为存在候选或缺证据，沿文件与规则复核后继续，不自动判违规或中止整个任务。动态映射、DTO 全字段、基础能力实际复用、事务和权限生效均需语义与实际验证。

## 实现与完成

核对现状和调用方 → 选择已有规范与能力 → 实现当前需求 → 运行与改动相称的构建和自测 → 汇总实际结果。按[任务路由](references/任务路由.md)将实际变更映射到命中规则正文、正反例和验证，不只读路由就开工；实现中新增依赖、共享资源或公开行为变化时补读对应条款，不回头加载全库。能力包说明框架提供什么，基础规范约束如何开发；不得凭依赖存在推断能力已启用。

内部与对外 HTTP 接口采用同一 `R<T>`、`CommonConstants.SUCCESS=200` 及公共分页对象目标契约，但按[API 边界与网关路由](references/API边界与网关路由.md)分别处理网关登记、认证、公开字段和 SDK 交付。外部响应先按已确认契约适配，不另定 AURA 成功码；框架尚未提供目标分页类型时，报告版本和实现缺口，不虚构 API。

存量改造先识别受影响接口、调用方与兼容约束，再在授权范围内实现。普通开发只做当前任务所需检查；明确要求规范审查时进入独立审查入口，不把全部旧项目开发都变成先审查。

交付前按[验证检查](checklists/validation.md)核对行为主张与实际断言，再反查每类实际变更的证据与缺口；在现有任务记录或交付说明简述“命中规则→改动→验证/未验证”，不新建强制表单。代码完成、构建、自测、联调分别报告；测试删除、依赖升级或实现改变后，重核此前通过声明和文档各处是否仍属当前基线。缺少关键契约或版本时只停止相关推断，不改框架规则，不把未运行结果写成通过。
