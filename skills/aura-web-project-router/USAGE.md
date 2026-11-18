# AURA 项目分流使用说明

## 适用场景

已确认维护 AURA 框架库时，按框架职责交接，编辑前使用 `aura-web-develop` 的适用规范。综合端业务项目的样式或按钮小改、新功能、故障排查、代码审查、结构咨询及联邦任务按当前请求分流。同一项目的后续请求可复用有效身份。

确认 Vue 3 与 Vite 后，四项身份完整命中为 `Integrated`；无命中为 `NotPIGX`；部分命中为 `IncompleteCandidate`。清单缺失、无法解析或技术栈不符同样输出 `NotPIGX`，用 `frontendStackIssue` 说明原因，此时未读取四项身份文件。有 Aura 专有证据的候选在明确前端规范或正式审查时可交 `aura-web-review`。只有联邦插件命中的项目不进入 Aura 专项。

## 调用与可用技能

使用 `$aura-web-project-router`，提供项目路径和本次需求。Agent 将实际可用技能通过 `-AvailableSkills` 传入脚本；不传该参数时输出只是推荐，不代表已经安装或调用。缺失时说明用途与影响，未经明确授权不安装；必需技能缺失暂停相应分支，地图/视频专项按已有降级规则处理。

代码审查和结构咨询交 `aura-web-review` 依用户范围选择交付。业务修改交 `aura-web-develop` 执行包括注释在内的开发要求，地图和视频按需组合。普通业务诊断保留只读范围。脚本推荐仅辅助判断，Agent 核对原意。

检查模块联邦配置、排查公共依赖预构建或首次菜单重载时，交 `aura-module-federation-check` 核实证据，按开发规范修复已确认且方案明确的问题并复检。有实质方案取舍时请用户决策。专项审计、只读检查、只报告、先给建议、改前基线和仅复检按原范围取证。明确要求修改联邦或预构建配置时，由 Web 开发规范主导实现，联邦专项检查提供改前基线和改后复检。

脚本的 `isAuditOnly` 为 `true` 表示识别到只读的联邦专项意图，技能推荐仍取决于项目身份和可用技能。普通专项检查的该字段为 `false`，由联邦技能按证据判断是否进入整改。

## 示例提示词

- `识别当前项目；审查前端代码与规范并生成六文件结果包，不修改代码。`
- `审查这次修改的 diff。`
- `只看这个按钮为什么置灰，不改代码。`
- `修复 aura-web-kit 包内公共 Hook 的状态更新。`
- `看下地图页面怎么拆，先给建议。`
- `还是刚才的订单列表，把按钮间距调小，再加一个全屏按钮。`
- `识别当前项目；新增设备 CRUD 页面和菜单按钮。`
- `识别当前项目；新增地图点位与视频监控页面。`
- `检查模块联邦配置。`
- `检查模块联邦配置，范围只限 shared。`
- `只审计模块联邦配置，不修改代码。`
- `只修复模块联邦的 shared，不改其他文件。`
- `排查 Vite dev 首次进入设备菜单时为什么会重载。`

## 识别方法与版本来源

版本 1.0.5 保留既有输出字段及 Integrated/NotPIGX/IncompleteCandidate 类型，并补充技术栈识别原因。四项为 currentRemoteConfig、exposeModules、src/config/aura/federation.ts 中 @fxft/aura-web-kit/federation 当前绑定，以及同一 vite.config 文件中的 @module-federation/vite 与 federation()。

第三项依据 `aura-module-federation-check` 的 `scripts/lib/project-type.ps1` 及随包框架规范。技术栈声明与四项识别口径参照 `aura-web-review` 的 `scripts/Review-Frontend.ps1`。检测方法随包实现，可独立安装使用。

脚本需已有 PowerShell；中文脚本保存 UTF-8 BOM 以支持 Windows PowerShell 5.1，同时支持 PowerShell 7。执行 `scripts/test-detect-pigx-project.ps1` 做分流回归，`scripts/validate-skill.ps1` 做结构校验。
