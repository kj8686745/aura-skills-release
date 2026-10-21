# 后端开发技能使用说明

安装本技能完整目录后，可直接描述 AURA 后端业务需求，或显式调用 `$aura-base-backend-development`。基础编码与七类框架能力的使用资料已在同一包内，不必分别指定能力技能。

> 使用 $aura-base-backend-development 实现设备管理模块的查询和状态变更，复用当前数据访问、用户及租户能力，核对权限、事务和失败结果。

> 使用 $aura-base-backend-development 为导入任务接入文件存储与 Socket.IO 进度通知，先核对项目框架版本、认证方式、namespace 和部署实例数，再实现实际支持的能力。

> 使用 $aura-base-backend-development 实现设备查询对外 API，保持与内部相同的响应及公共分页目标契约，同步设备模块接口文档。

说明项目位置、需求和已有契约即可；依赖与配置能够从项目查到时不必重复填写。技能先选规范和能力模块，再读取所需示例，不加载所有资料。

只需规范审查时使用 `aura-backend-compliance-review`；技术详细设计和系统初始化各有独立入口。它们不是完成普通后端实现的强制安装前提。

## 随包脚本

需要 PowerShell 7（`pwsh`）。命令在技能目录运行，`ModulePath` 相对项目根；只选实际变更模块，不默认盘点全仓。盘点不会运行 Maven、Gradle、服务或联网解析依赖，也不输出配置值。

```powershell
./scripts/inspect-backend-project.ps1 -ProjectPath <项目根> -ModulePath order-service
./scripts/check-backend-rules.ps1 -ProjectPath <项目根> -ModulePath order-service -OutputPath <临时目录>/backend.json
./scripts/inventory-api-contracts.ps1 -ProjectPath <项目根> -ModulePath order-service -OutputPath <临时目录>/api.json
./scripts/check-api-document.ps1 -DocumentPath <模块docs>/接口文档.md -InventoryPath <临时目录>/api.json -Json
```

前两者支持 `-OutputPath` 写详细 JSON；不传则不写文件。小范围需要细节时使用 `-Json`，较大模块从结果文件仅筛选 `candidates`、`unresolved` 或本次类型，避免全文加载。接口盘点与文档检查和接口技能携带同源实现，安装本技能即可运行。临时 JSON 不属于模块交付物，用完删除。

盘点的依赖版本是源码声明，可能包含属性表达式，不等于最终依赖树。规则脚本列出分层、响应分页、OpenAPI、线程和重复基础设施候选，附规则编号、路径、行号及复核提示；没有命中不代表合规。基础能力复用仍须检查真实公开 API 和调用链，不因一个依赖或 import 存在而通过。接口文档脚本只核对可解析结构，须沿 DTO、异常与网关配置补齐字段和行为。

退出 `0/1/2` 分别表示所请求静态处理完成、错误、需要继续补证。构建、自测、服务运行和联调分别报告实际结果，不用脚本状态替代。
