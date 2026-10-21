# PIGX 项目分流使用说明

## 适用场景

当前 Vue/Vite 项目框架未知，任务涉及 Aura 业务开发、前端规范审查、地图视频或模块联邦时使用。只读识别与分流，不实现业务或写管理端。

四项完整命中为 Integrated；普通 Vue/Vite 无命中为 NotPIGX；部分命中为 IncompleteCandidate。有 Aura 专有证据的候选在明确前端代码/规范审查任务中可交 aura-web-review 使用 ReviewCandidate 盘点，按最新规范报告缺项；普通业务仍不降低门槛。只命中联邦插件不能自动接管。

## 调用与可用技能

使用 `$aura-web-project-router`，提供项目路径和本次需求。Agent 将实际可用技能通过 `-AvailableSkills` 传入脚本；不传该参数时输出只是推荐，不代表已经安装或调用。缺失时说明用途与影响，未经明确授权不安装；必需技能缺失暂停相应分支，地图/视频专项按已有降级规则处理。

综合前端代码/规范审查交 aura-web-review；仅模块联邦专项审计交 aura-module-federation-check；业务实现交 aura-web-develop，地图和视频按需组合。脚本关键字仅辅助意图识别，混合任务由 Agent 核对实际范围。

## 示例提示词

- `识别当前项目；审查前端代码与规范并生成六文件结果包，不修改代码。`
- `识别当前项目；新增设备 CRUD 页面和菜单按钮。`
- `识别当前项目；新增地图点位与视频监控页面。`
- `只审计模块联邦配置，不修改代码。`

## 识别方法与版本来源

版本 1.0.4 保留既有输出字段及 Integrated/NotPIGX/IncompleteCandidate 类型。四项为 currentRemoteConfig、exposeModules、src/config/aura/federation.ts 中 @fxft/aura-web-kit/federation 当前绑定，以及同一 vite.config 文件中的 @module-federation/vite 与 federation()。

第三项依据当前 aura-module-federation-check 的 scripts/lib/project-type.ps1 及最新随包框架规范，替换旧 utils 注册表路径；不要求恢复旧副本，不维护旧版适配。与 aura-web-review 的四证据方法一致，不以项目名或单一依赖代替。方法已经随包实现，不依赖另一技能安装或联网取源码；当前修改尚未提交，不能称发布完成。

脚本需已有 PowerShell；中文脚本保存 UTF-8 BOM 以支持 Windows PowerShell 5.1，同时支持 PowerShell 7。执行 `scripts/test-detect-pigx-project.ps1` 做分流回归，`scripts/validate-skill.ps1` 做结构校验。
