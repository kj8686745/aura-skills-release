# 后端开发技能使用说明

> 优化设备按标签筛选的分页查询：明确主记录分页、可信数据范围和总数口径，使用现有 Mapper/XML 实现；只检查本次 SQL，不逐设备查标签，不把静态检查写成性能通过。

> 为已有表增加字段并迁移历史数据：沿用现有迁移工具，核对旧实例兼容、分批回填、校验、约束收紧及恢复；不重新生成整个模块，不擅自连接真实数据库。

安装本技能完整目录后，可直接描述 AURA 后端业务需求，或显式调用 `$aura-base-backend-development`。数据库、事务、Entity、Mapper、SQL 和迁移属于本技能的后端数据库模块；基础编码与七类框架能力的使用资料已在同一包内，不必分别指定数据库或能力技能。

> 使用 $aura-base-backend-development 初始化一个 Java 21 + Spring Boot 后端项目，先确认真实 BOM 和构建版本，再建立最小工程结构、启动入口、README/docs 和基础能力接入，不创建前端或空业务目录。

> 使用 $aura-base-backend-development 研读指定后端模块，说明它做了什么、主要类各自职责和关键流程，在模块 docs 中提供带源码导航的接手说明。扫描摘要只作定位依据；不改业务代码，不扩大为全项目规范审查。

> 使用 $aura-base-backend-development 为指定模块补充类级和关键逻辑注释：读取真实方法和必要调用链后直接在授权范围内写回，说明业务边界和关键分支原因，不改业务逻辑；批量插入可使用注释计划脚本。

> 使用 $aura-base-backend-development 实现设备管理模块的查询和状态变更，复用当前数据访问、用户及租户能力，核对权限、事务和失败结果。

> 使用 $aura-base-backend-development 为设备模块新增数据库表、Entity、Mapper、分页查询和事务写入；先按数据库操作与事务路由盘点真实依赖、迁移入口和数据范围，再实现并验证正常读写与失败回滚。

> 使用 $aura-base-backend-development 为设备详情增加缓存，先明确键前缀、租户范围、TTL、数据库事实来源、缓存 miss 回源、缓存不可用降级和提交后失效，再生成缓存契约常量并实现适配器。

> 使用 $aura-base-backend-development 为导入任务接入文件存储与 Socket.IO 进度通知，先核对项目框架版本、认证方式、namespace 和部署实例数，再实现实际支持的能力。

> 使用 $aura-base-backend-development 实现设备查询对外 API，先按 API 边界与网关路由区分内部/对外，核对 `/openapi`、`@PlatfomApi`、HMAC 和自动收录；响应和分页仍与内部保持统一，同步设备模块接口文档。

内部接口不添加 `@PlatfomApi`，不因未使用 `/openapi` 被判错；对外 OpenAPI 必须核对公开路径、平台登记、网关最终路径、公开 DTO、签名认证和 SDK/文档交付。边界无法确认时只保留未证实，不猜测。

说明项目位置、需求和已有契约即可；依赖与配置能够从项目查到时不必重复填写。技能先选规范和能力模块，再读取所需示例，不加载所有资料。

上下文预算：默认只加载本技能、一个任务路由和一个命中条款；不把来源 JSON、完整规范矩阵或全部能力资料带入会话。详细脚本结果写入临时目录后，用 `select-json-summary.ps1` 提取计数和命中项；普通 CRUD 不同时加载接口或审查技能。

只需规范审查时使用 `aura-backend-compliance-review`；独立技术详细设计仍使用 `aura-detailed-design`。后端项目初始化可以由本技能完成；完整前后端工程初始化再组合 `aura-base-project-engineering`。

通用后端开发以本技能为入口，不同时装载旧 `aura-backend-development` 的规则。若安装列表仍有旧入口，先核对安装来源和独有内容，再由维护者清理；本技能不会自行卸载其他技能。普通任务只需在既有说明中简述适用规则、实际改动和验证缺口，不另交一套审查报告。

## 随包脚本

需要 PowerShell 7（`pwsh`）。命令在技能目录运行，`ModulePath` 是相对项目根的目录，不接收文件；单文件任务选择其所属目录，再筛选该文件的候选，不把关联目录全算本次改动。只选实际变更模块，不默认盘点全仓。盘点不会运行 Maven、Gradle、服务或联网解析依赖，也不输出配置值。

```powershell
./scripts/inspect-backend-project.ps1 -ProjectPath <项目根> -ModulePath order-service
./scripts/inspect-backend-onboarding.ps1 -ProjectPath <项目根> -ModulePath order-service -OutputPath <临时目录>/onboarding.json -Json
./scripts/check-backend-rules.ps1 -ProjectPath <项目根> -ModulePath order-service -OutputPath <临时目录>/backend.json
./scripts/check-backend-project-init.ps1 -ProjectPath <项目根> -ModulePath order-service -IncludeProjectEntry -Json
./scripts/prepare-backend-project.ps1 -ProjectPath <项目根> -ModulePath order-service -BuildSystem Maven -PackageName com.example.order -Mode Plan
# 确认真实 Java/Spring 版本后再生成；Apply 不覆盖已有文件。
./scripts/prepare-backend-project.ps1 -ProjectPath <项目根> -ModulePath order-service -BuildSystem Maven -PackageName com.example.order -JavaVersion 21 -FrameworkVersion <真实版本> -IncludeProjectEntry -Mode Apply
# 数据库层重复结构先使用 Plan 预览，再按确认后的字段清单 Apply；不覆盖已有文件。
./scripts/prepare-database-module.ps1 -ProjectPath <项目根> -ModulePath order-service -PackageName com.example.order -EntityName Order -TableName orders -FieldJson <临时目录>/order-fields.json -EntityMode Standalone -Mode Plan
# 只有核实项目确实继承 AURA BaseEntity 时才使用 AuraBaseEntity。
./scripts/check-database-module.ps1 -ProjectPath <项目根> -ModulePath order-service -OutputPath <临时目录>/database.json -Json
# 初始化项目具备真实依赖和构建环境后，另行执行构建与启动验证；启动探针不默认触发。
./scripts/test-backend-web-startup.ps1 -ProjectPath <项目根> -ModulePath order-service # 仅在明确接入 Web 能力时验证容器和临时端口
./scripts/inventory-api-contracts.ps1 -ProjectPath <项目根> -ModulePath order-service -OutputPath <临时目录>/api.json
# 需要代码返回模型字段候选时追加：-IncludeResponseFields
./scripts/check-api-document.ps1 -DocumentPath <模块docs>/接口文档.md -InventoryPath <临时目录>/api.json -Json
```

前两者支持 `-OutputPath` 写详细 JSON；不传则不写文件。小范围需要细节时使用 `-Json`，较大模块从结果文件仅筛选 `candidates`、`unresolved` 或本次类型，避免全文加载。接口盘点与文档检查和接口技能携带同源实现，安装本技能即可运行。临时 JSON 不属于模块交付物，用完删除。

摘要筛选示例：

```powershell
./scripts/select-json-summary.ps1 -InputPath <临时目录>/backend.json -PathFilter order-service -MaxItems 20
```

前两个命令的 `-ApiMode Auto` 默认根据当前范围的 HTTP 线索选择是否调用接口盘点；无相关线索返回 `api.status=not-triggered`，不因纯 Provider/工具目录没有接口就制造缺证据项，也不据此断定没有动态或继承接口。任务已明确涉及 HTTP、但映射依赖自定义注解或继承时，传 `-ApiMode Required` 强制盘点，保留识别不到的契约待人工核对。`reviewFocus` 给出依赖、共享资源、外部调用、错误等选读提示及代表性路径，不自动判断规则适用或规范通过。

盘点的依赖版本是源码声明，可能包含属性表达式，不等于最终依赖树。规则脚本列出分层、响应分页、OpenAPI、线程和重复基础设施候选，附规则编号、路径、行号及复核提示；没有命中不代表合规。基础能力复用仍须检查真实公开 API 和调用链，不因一个依赖或 import 存在而通过。接口文档脚本只核对可解析结构，须沿 DTO、异常与网关配置补齐字段和行为。

退出 `0/1/2` 分别表示所请求静态处理完成、错误、需要继续补证。构建、自测、服务运行和联调分别报告实际结果，不用脚本状态替代。
