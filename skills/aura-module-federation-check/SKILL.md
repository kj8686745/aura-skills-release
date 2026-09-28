---
name: aura-module-federation-check
description: 自动识别 Vue 3 + Vite 项目属于 PIGX 综合端、模块联邦生产端或消费端，并检查 PIGX 综合端的模块联邦身份、依赖、Vite 配置、shared singleton、运行时外壳、i18n、样式、静态资源和构建产物。模块联邦配置由 Web 开发技能实现，本技能提供改前基线、改后复检与对外接入说明；首版生产端或消费端仅报告类型和证据。
---

# Aura PIGX 模块联邦检查

当前版本：`1.0.3`。

只读识别与审计 PIGX 综合端，提供改前基线、改后复检。配置实现由 `aura-web-develop` 主导；仅在用户明确要求修复时修改项目，不猜测部署地址、远程拓扑或后台菜单。

## 首次调用提示

简要说明审计范围；已有项目路径和需求时直接执行。只有用户询问用法时读取 [使用说明](USAGE.md)。

## 执行与按需读取

1. 运行 `scripts/check-module-federation.ps1 -ProjectPath <项目路径>`。需要机器结果加 `-Json`，指定构建清单加 `-ManifestPath`，核验菜单传真实 `-ComponentPath`。
2. 仅 `Integrated` 进入完整审计；`Provider` / `Consumer` 报告类型证据及专项审计尚未支持；`Unknown` 报告不足或冲突证据并停止，不猜测。
3. 综合端审计读取 [规则矩阵](references/integrated-rule-matrix.md)，按 [验证清单](checklists/integrated-validation.md) 补充构建、独立运行和宿主加载检查。只报告实际执行结果。
4. 类型解释、退出码或编写报告时读取 [类型与报告契约](references/audit-report-contract.md)。
5. 综合端完成修改且复检无确定错误时，读取 [对外接入说明](references/provider-consumer-handoff.md) 并交付接入参数。用户明确指定消费方项目且要求接入时，按该文档边界修改真实配置。

## 规范依据

优先级：用户要求 → 项目源码、类型、实际依赖和产物 → [正式规范](knowledge/PIGX前端开发规范/模块联邦开发技术规范.md) → 规则矩阵与脚本。出现规范冲突或配置细节疑问时读取正式规范。

有效模板基线包含 `element-plus@2.14.3` shared singleton，不沿用“Element Plus 不加入 shared”的旧规则。未命中的参考不加载；同一会话未变化的资料不重复读取。
