# 前端代码审查技能用法

## 正式审查（默认）

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

`aura-web-develop` 自动以 `mode=development-self-check` 调用；直接使用时提供项目、业务块、需求/原型、代码基线、业务说明、必需检查和记录位置。它是技能语义模式，不是脚本参数。按[开发自检](references/development-self-check.md)读取相同规则与适用规范；READ-04按真实场景语义完整性与实现一致性核验，不以固定标题、顺序或字段表判缺项，源码字段注释另行核对，只读检查并保留一份轻量记录，不创建六文件或结果包，不调用 Collect/Check。问题交开发技能修复并复查；同一 Agent 执行如实标记开发自检。全部适用必需检查和测试通过才返回通过，供开发技能生成“自检通过，待人工审查”的报告。

正式审查与开发自检均强制检查业务枚举/字典展示使用 `AuraDictTag` / `AuraDictText`，不接受手写展示转换。只核公开契约；其余 aura-ui 专项仍排除，缺组件如实记录偏差或缺证。
