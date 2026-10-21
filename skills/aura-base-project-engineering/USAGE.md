# 系统初始化与工程维护技能使用说明

新建工程、增加模块或局部修改配置/依赖/构建时，可直接描述目标和项目路径，也可显式使用 `$aura-base-project-engineering`。已有项目能查到的结构和构建事实不用重复填写；新工程请给出实际框架模板或版本依据，本技能不内置可直接复制的框架脚手架。

示例：`$aura-base-project-engineering 检查当前 AURA 服务新增订单模块应放在哪一层，并说明需要调整的依赖和构建入口。`

示例：`$aura-base-project-engineering 仅修改订单模块的配置默认值并同步已有配置说明，不重建项目结构，不初始化 AI 会话。`

## 随包检查脚本

PowerShell 7，在技能目录运行；模块路径相对明确的项目根，默认不扫描同级其他工程。

```powershell
./scripts/check-project-engineering.ps1 -ProjectPath <项目根> -ModulePath order-service
./scripts/check-project-engineering.ps1 -ProjectPath <新项目根> -IncludeProjectEntry
./scripts/check-project-engineering.ps1 -ProjectPath <项目根> -ModulePath order-service -OutputPath <临时目录>/engineering.json
```

默认终端仅摘要，不修改文件或运行构建。需要较小范围的详细结果时用 `-Json`；较大模块写临时 JSON 后只读命中问题。`-IncludeProjectEntry` 显式核对项目根 README、根 docs 入口、链接及已有根构建声明，不递归读取其他模块；局部配置任务不因调用工具自动扩大为根入口整改。模块已有独立文档时检查入口，没有独立文档不强制新建 docs。

检查可解析的 Maven 模块和字面 workspace 路径、文档直接链接及空目录。Gradle DSL、workspace 通配表达式、继承配置和部分 Markdown 语法会标为待核实；XML/JSON 解析失败和已确认失效路径是确定错误。配置仅列路径、不输出值；不联网、不执行 package scripts、Maven 或 Gradle，不把依赖声明当作最终依赖树。脚本不检查模板匹配、所有循环依赖、功能或文档语义。

退出 `0/1/2` 分别表示静态范围内未发现已识别问题、确定错误/执行失败、候选或检查不完整。根 README 的主题完整性、模块职责、默认配置与恢复、真实构建和运行仍需复核。版本只读取 `VERSION`，来源精确记录在 `references/source.json`。临时结果用完清理，不作为业务正式文档。
