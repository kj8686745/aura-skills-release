---
name: aura-backend-compliance-review
description: "只读审查 AURA Java/Spring 后端变更、存量接口或全项目的规范偏差，核对基础能力复用并交付带证据的报告；变更用单报告，全项目用六文件包，不执行代码整改。"
---

# AURA 后端与接口规范审查

每次审查必须先交付人类可读的结果总览，再交付详细报告和机器证据。总览只保留结论、范围、已确认事实、未证实项和下一步；JSON、完整候选和逐文件清单放在同一项目结果目录中作为证据，不作为默认阅读入口。

一次调用连续完成可执行审查并交付报告，不按模块反复等待确认。只读目标源码、锁文件和配置；补证不能隐含修改业务、访问生产或发布。版本见 `VERSION`，来源见[规范来源与验证](references/规范来源与验证.md)。

## 先选择任务

| 请求 | 执行范围 | 报告 |
|---|---|---|
| 审查本次修改、提交或文件清单 | 差异及受影响调用、公共契约和配置链，不默认扩为全项目 | 一份六章报告 |
| 审查整个后端项目 | 全部纳入资产与适用规则域 | 固定六文件包 |
| 接口专项 | 指定模块/接口及必要调用方；选读[接口入口](references/专项/接口专项/审查入口.md) | 有界局部用单报告；全量专项或明确要求结果包时用六文件 |

范围与格式分别记录。有 Git 差异、明确提交或文件清单时默认变更审查；明确接口路径时进入接口专项；只有明确“全项目”才进入全项目六文件包；完全没有范围时先做最小范围盘点并标记不完整，不预加载全项目规范。缺 Git 基线时可按用户清单检查，但不能声称差异完整。项目无法定位或必须扩大授权时集中询问，其余证据缺口记录后继续。

## 上下文预算

默认只读取本技能、一个审查执行路由和命中的规范/正反例；变更或接口专项不读取 `source.json` 全文、完整规范矩阵、全部能力入口或外部 SDK 内部源码。先用 `-OutputPath` 保存详细 JSON，再用 `select-json-summary.ps1` 提取计数、问题和待核对项。`-IncludeFiles`、`-IncludeCapabilityCandidates`、`-IncludeResponseFields`、`-IncludeRequestFields` 仅在当前范围需要时显式加入；不同时加载开发技能和接口技能，除非要核对同一契约的实现与文档。

## 连续执行

1. 核对显式指定技能与规范来源；旧入口失效或契约矛盾时说明冲突，不静默混用规则。固定仓库、分支/提交、工作树摘要及输出位置。输出不计入被审资产。变更模式记录 base/head 与增删改；删除文件从基线取证，当前不存在不是读取失败。
2. 按[执行路由](references/后端审查执行路由.md)建立对象目录和规则范围。变更只选命中域；全项目先用规范矩阵盘点全部域，再分域读正文与正反例。前端专项不在本技能范围；未查域不能标通过。先用 `inspect-review-scope.ps1` 固定项目/模块边界和依赖清单，避免把输出目录、链接目录或外部 SDK 内部纳入审查。
3. 运行下述工具采集资产、接口与候选；沿真实类型、调用、配置链核实。对 SDK、Starter、Feign Client 等外部依赖，只核对当前项目的依赖声明、配置、调用、适配和公开契约，行为链在项目内 `Client/Adapter` 出口停止；不进入缓存、JAR、反编译结果、邻仓库或 SDK 内部源码。工具不支持的映射或外部代码保持未知，不用检索零命中证明合规。
4. 必查当前范围涉及的基础业务与公共支撑是否复用。在范围盘点中追加 `-IncludeCapabilityCandidates` 获取候选账本；按执行路由的能力表只读命中章节，核对公开版本、实际依赖/配置/调用及重复实现候选。无命中仍须确认适用性，不把候选当结论。没有该功能不要求强装依赖；专项能力仅在需求、代码、依赖、路由或配置触发时追加。启用候选账本后，候选能力必须在同一审查报告/结果包的能力复用章节完成回写；未回写或仍为 `not-evaluated` 时结果只能标记 `partial`，不得宣称审查交付完整。
5. 按执行路由建立批次队列，逐规则×真实适用单元取证，分别记录执行进度、四种结论和缺口；完成一批即更新同一报告/包并继续下一批。未查不改写为缺运行环境，无候选也须查对应规则；禁止按域套话或默认填状态。基础能力编号不替代规则 ID，未知契约不据此扣分。构建/测试仅在授权和环境允许时补证，不改代码制造通过。
6. 按[双模式模板](references/审查结果包模板.md)整理已有判断并自检；按[完成门槛](references/后端审查完成门槛.md)复核范围、具体 U/E、行为链、能力候选回写、统计和未知边界。启用能力候选时追加 `check-capability-ledger-report.ps1`；它返回 `partial` 说明交付资料仍缺能力结论，不是业务偏差。尚有可执行静态批次则继续；实际中断在同包留检查点。脚本通过不等于取证充分，须人工复核误报、严重性与关闭条件。

审查内外 API 均对照同一公共 `R<T>`、`CommonConstants.SUCCESS=200` 和公共分页目标契约；先核实真实框架类型和适配链，不新造类型或把外部 SDK 原始响应值当成 AURA 标准。对外 API 另核查 `/openapi`、`@PlatfomApi`、网关登记和实际收录证据；不向内部接口机械补注解。契约变更还须核对模块接口文档是否同步。

## 随包辅助工具

PowerShell 7；在技能目录执行，项目及模块路径换为实际范围。脚本不写报告、不改目标项目；默认摘要，`-Json` 返回逐项数据，按需筛选而非全文读入上下文。

```powershell
./scripts/inspect-backend-project.ps1 -ProjectPath '<项目根>' -ModulePath 'device' -Json
./scripts/inspect-review-scope.ps1 -ProjectPath '<项目根>' -ModulePath 'device' -Json
# 复用核查在同一次范围盘点追加，不需要另扫一遍：
# -IncludeCapabilityCandidates
# 需要冻结 Git 基线并纳入当前工作树时：
./scripts/inspect-review-scope.ps1 -ProjectPath '<项目根>' -ModulePath 'device' -BaseRef '<基线提交>' -HeadRef '<目标提交>' -IncludeWorkingTree -Json
# 只有需要逐文件资产目录时追加：-IncludeFiles
./scripts/check-backend-rules.ps1 -ProjectPath '<项目根>' -ModulePath 'device' -Json
./scripts/inspect-database-changes.ps1 -ProjectPath '<项目根>' -FilePath @('<本次Mapper.xml>','<本次迁移.sql>') -OutputPath 'docs/临时验证物料/后端规范审查/查询迁移候选.json' -Json
./scripts/check-review-result.ps1 -Mode Change -ResultPath '<单报告.md>' -MatrixPath '<技能目录>/references/standards/01-基础编码规范/规范矩阵.md' -Json
./scripts/check-review-evidence.ps1 -Mode Change -ResultPath '<单报告.md>' -Json
./scripts/check-capability-ledger.ps1 -InputPath '<范围盘点 JSON>' -Json
./scripts/check-capability-ledger-report.ps1 -LedgerPath '<范围盘点 JSON>' -ResultPath '<审查报告或结果包>' -Mode Change -Json
# 全项目或全量专项六文件包使用 -Mode Project -ResultPath '<结果包目录>'
```

盘点/候选工具复用后端开发同源实现，完整携带依赖，不要求另装开发技能。它们仅处理指定模块；变更时可对所属模块采集上下文，但区分差异对象、关联对象和未审对象，不能把盘点到的文件全算已查。按需可直接调用 `inventory-api-contracts.ps1`，需要代码返回模型字段候选时追加 `-IncludeResponseFields`，请求体字段候选时追加 `-IncludeRequestFields`，避免重复接口采集。详情与工具边界见执行路由。

结果 JSON 继续定位时使用 `select-json-summary.ps1 -InputPath '<临时 JSON>' -PathFilter '<模块或文件>' -RuleId '<规则>' -ApiPath '<接口路径>'`，只把摘要和命中项带回会话；完整文件清单、字段候选和能力候选不作为默认上下文。交付目录固定先放 `00-审查结果总览.md`，变更模式的详细报告放在 `01-变更审查报告.md` 或同目录既定报告名，原始 JSON 放入 `证据/` 或以“证据”前缀命名。

结果检查入口传入 `-MatrixPath` 后会自动将报告引用的规则 ID 与随包正式规范矩阵比对；只阻断不存在的规则 ID，不把未引用规则当作偏差或要求局部审查覆盖全矩阵。`check-review-matrix.ps1` 仍可单独用于排错和统计。

结果交付前可运行 `check-review-evidence.ps1` 检查明显凭据模式和 SDK/JAR/邻仓库越界线索。命中凭据才阻断；范围线索只返回待人工复核，不回显原始值，也不替代项目合规结论。

能力候选账本可用 `check-capability-ledger.ps1` 做结构复核；它同时接受范围结果中的 `capabilityReuse` 和独立账本，要求保留 `candidate-only`、`reviewStatus=not-evaluated` 及路径/行号证据，不自动把候选升级为复用或偏差。

正式交付前使用 `check-capability-ledger-report.ps1` 检查候选能力是否进入结果包的能力复用章节。缺少回写或仍未分类时返回 `partial`，不生成偏差；人工确认后再补充复用、重复实现、未证实、不适用及 E/F/C 回指。

传入 `BaseRef/HeadRef` 后，范围盘点结果会增加 `git` 节点，记录仓库根目录、分支、提交、工作树、未跟踪文件、输出路径排除项和稳定 `scopeId`。未提供 `BaseRef` 时只能记录工作树，结果标记为 `partial`，不能声称差异相对基线完整；Git 范围脚本不判断规则适用性、调用链或项目合规。

`ModulePath` 是项目相对目录，不接收文件。`api.status=not-triggered` 只表示当前范围无 HTTP 线索、未执行接口盘点，不是接口域通过；已知涉及 HTTP 时用 `-ApiMode Required`。`reviewFocus` 只帮助选读，不能代替规范矩阵、适用性判定或规则覆盖统计。

配置证据默认只输出路径、字节数和内容 SHA-256，不输出键值；`check-backend-rules.ps1` 会对指定范围内 Java 的受控字符串/字符数组声明生成敏感配置候选，只记录字段名和行号，并过滤环境变量引用与常见占位符。候选仍须人工区分真实凭据、测试夹具和示例值；该扫描不覆盖历史提交、镜像、日志和二进制。


退出 `0` 表示所请求静态处理未识别到问题，不代表项目合规；`1` 为执行/格式错误；`2` 为候选待复核或不完整。报告自检检查的是报告，不代替业务取证。敏感值落盘前脱敏；工具没有覆盖的规则仍须人工核对。
