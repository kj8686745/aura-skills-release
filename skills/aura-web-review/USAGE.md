# 前端代码审查技能用法

## 按范围调用

明确限定文件、diff、一次变更或局部模块时默认使用 `change-review`，交付一份变更审查报告；全项目、完整规范或明确要求正式审查时使用 `formal-review` 六文件包；开发闭环使用 `development-self-check` 轻量记录。未提供范围时按全项目正式审查。三种模式均只读，不是 PowerShell 参数。

例如：`$aura-web-review 审查当前未提交的设备编辑变更及必要调用方，输出一份报告，注明版本、适用规则、问题证据和未覆盖项。`

变更报告不调用 Collect/Check、不建全规则矩阵；零发现仍需说明实际覆盖和限制，不代表全项目合规。详见[变更审查](references/change-review.md)。

## 正式审查

在 IDE Agent 中调用 `$aura-web-review`：

> 按最新前端规范审查当前 Aura 项目，aura-ui 仅检查 AuraDictTag / AuraDictText / AuraDictSelect 的公开接入及筛选/表单/字典展示消费、ui-plus 正常检查；连续完成静态取证，按原六文件格式输出，中文解释规范要求、实际检查和真实缺证，不修改业务源码。

只审查前端源码、配置、依赖与已有产物。规范来自随包 `knowledge/PIGX前端开发规范`；sourceRepository/sourceCommit 仅供维护追溯，无需联网拉取仓库。最新基线统一使用，不做旧版适配。

Aura 身份以基础配置、expose 聚合、当前 web-kit 运行时绑定和 Vite federation 四项证据识别。缺项且有 Aura 专有线索时，明确审查任务可用 `-ReviewCandidate` 继续盘点并报告偏差；普通 Vue/Vite 或单一联邦插件不据此套用 Aura 规范。

## 正式审查辅助命令

从技能根目录运行，需要已有 PowerShell 5.1 或 7；`pwsh` 表示 PowerShell 7，5.1 用 `powershell.exe` 替换。Agent 或 IDE 不自动提供运行时，不安装任何额外工具链。

```powershell
pwsh -NoProfile -File scripts/Review-Frontend.ps1 -Action Collect -ProjectRoot 'E:/code/frontEnd/company/实际项目' -ReviewCandidate
pwsh -NoProfile -File scripts/Review-Frontend.ps1 -Action Check -ReportDirectory '<Collect返回的reportDirectory>'
```

默认结果包为 `<ProjectRoot>/审查结果包-项目名-提交短号-日期/`，已有目录追加序号不覆盖；无 Git 用时间标记替代提交短号。Collect 在包内 `证据/inventory.json` 保存盘点，并返回 `reportDirectory`。Agent 在该目录按模板直接编写六份报告。所有结果包及证据均从被审资产排除；不修改源码、lock、env 或 gitignore。

用户显式指定位置时可传 `-OutputDirectory` 覆盖默认盘点目录；项目内必须位于根下“审查结果包-*”专用目录或其子目录，项目外目录也支持。显式盘点文件已存在则拒绝覆盖；项目外显式目录同时作为返回的 reportDirectory。限定模块时在 PowerShell 会话传 `-Scope @('src/views/模块', 'src/api/模块')`。

Collect 只有摘要和候选，Check 只有结构/ID/普通本地链接检查。Agent 仍需完成规范理解、调用链、统计和复核；不能拿脚本零命中、Check 通过或大量未检查项充当审查完成。没有 PowerShell 时使用已有只读工具完成同样工作并记录脚本未执行，不阻断其余审查。以上脚本接口和六文件输出仅适用于正式模式。

`aura-ui` 仅纳入 `AuraDictTag` / `AuraDictText` / `AuraDictSelect`，其余范围排除且不计未证实；`ui-plus` 独立核对实际依赖、导出、resolver、地图视频调用。正式报告能力摘要必须两行分开，FE-025保留编号并注明纳入子项。01第5节和02矩阵以中文规范名配ID解释结果，详见 [取证与报告](references/取证与报告.md)。版本、候选资格、提交和发布状态分别管理。

## 开发自检

`aura-web-develop` 在功能开发闭环以 `mode=development-self-check` 调用，纯注释/说明整理默认不调用。明确要求验证/报告或真实项目门禁时按请求范围执行；直接使用时提供项目、业务块、需求/原型、代码基线、业务说明、必需检查和记录位置。它是技能语义模式，不是脚本参数。

按[开发自检](references/development-self-check.md)聚焦本批 diff 与必要上下文，复用有效资料和证据，不机械盘点 27 条 FE，不调用 Collect/Check 或生成六文件。READ-04 依真实场景与实现核验，源码字段注释单独核对；无独立新流程的局部修改复用现有说明。问题交开发技能整改；同一 Agent 执行如实标开发自检。全部适用必需项通过才返回通过，局部功能可把检查与交付合为简短开发记录，完整新功能或要求独立报告时另交报告，均标“自检通过，待人工审查”。

正式审查与功能开发自检按适用范围检查业务枚举/字典展示使用 `AuraDictTag` / `AuraDictText`，不接受手写展示转换。只核公开契约；其余 aura-ui 专项仍排除，缺组件如实记录偏差或缺证。

## API/类型注释范围

已请求 API/类型注释检查时请提供完整文件清单。当前源码版 0.3.0 按[声明字段门槛](references/development-self-check.md#read-0102-声明字段门槛)核对每个声明字段自己的相邻中文与真实含义。只读检查器为可选诊断，仅用户要求结构检查或真实项目门禁时运行；普通补注释不因此自动触发审查或检查。仅维护技能时业务源码只读。源码更新未安装或发布。
