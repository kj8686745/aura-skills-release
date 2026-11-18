---
name: aura-web-project-router
description: 为已知 AURA 前端项目或身份待确认的 Vue 3 + Vite 项目分流。开发、编辑、后续小改进入开发规范流程，框架内部修改按框架职责实施。按请求范围选择审查、诊断、咨询或模块联邦与 Vite 预构建专项。
---

# AURA 项目分流

当前版本：`1.0.5`。

每次收到 AURA 前端项目的请求，按本次意图选用技能。凡开发或编辑，实际执行者都须在首次编辑前使用 `aura-web-develop`，按改动执行全部适用规范并自检。已确认维护的是 `aura-web-kit` 等框架库时，直接交相应框架角色，沿用同一开发规范入口；下文四项证据用于识别综合端业务项目。只读请求按原范围分流。

## 首次调用提示

简要说明将识别项目并选择技能；已有路径和需求时直接推进。询问用法时才读取 [使用说明](USAGE.md)。

## 识别

同一项目根可复用仍有效的识别证据。先根据目标包的声明、公开入口和实际修改位置判断是否在维护框架本身。例如，目标包发布 `@fxft/aura-web-kit` 且改动位于该包的公共 Hook 源码时，直接按框架职责分流；业务项目从该包导入 Hook 时继续按业务项目识别。

需要确认综合端身份，或其依赖、身份配置发生变化时，运行 `scripts/detect-pigx-project.ps1 -ProjectPath <项目路径> -TaskDescription <用户需求> -Json`。先从 `package.json` 的 `dependencies` 与 `devDependencies` 确认 Vue 3 与 Vite 声明，再核对四项证据：

- `src/config/moduleFederationBaseConfig.ts` 的 `currentRemoteConfig`。
- `src/hooks/moduleFederation.ts` 的 `exposeModules`。
- `src/config/aura/federation.ts` 的 `@fxft/aura-web-kit/federation` 公共包运行时绑定。
- `vite.config.*` 的 `@module-federation/vite` / `federation()`。

不得用项目名、目录名、旧经验或单一模块联邦特征代替。

第三项采用当前框架绑定。四项全部命中才为 `Integrated`。缺少清单或无法确认技术栈时报告 `frontendStackIssue`，先定位实际前端包。方法来源见 [USAGE.md](USAGE.md)。

## 分流

| 结果 / 需求 | 后续动作 |
| --- | --- |
| `Integrated`，新增功能或任何业务编辑（含样式、配置和后续小改） | `aura-web-develop`，按改动执行通用要求、全部命中的专项规范和对应验收 |
| 综合端，审查 diff、局部代码或规范，评估结构或测试 | `aura-web-review`，传递原请求、明确范围和交付要求 |
| 综合端，业务故障排查 | 沿业务执行链定位原因；参考 `aura-web-develop` 的相关资料，只有用户要求修复才启动实施 |
| 综合端，开发 2D 地图点位、聚合、轨迹、热力、绘制或 GeoJSON | Web 技能 + `fmap-2d` |
| 综合端，开发视频直播、回放、点播、PTZ、分屏或拖拽 | Web 技能 + `fxft-video` |
| 综合端，明确修改联邦的 remote、expose、manifest、shared、远程菜单、运行时或相关预构建配置 | `aura-web-develop` 实现，`aura-module-federation-check` 做改前基线和改后复检 |
| 综合端，检查模块联邦配置，或排查 Vite 公共依赖预构建、组件 resolver、首次进入菜单重载 | `aura-module-federation-check` 先核实证据，按 `aura-web-develop` 修复已确认且方案明确的问题并复检。需要在有实质影响的方案间选择时交用户决定 |
| 综合端，联邦或预构建专项审计、只读检查、只报告、先给建议、单独做改前基线或改后复检 | `aura-module-federation-check` 按请求做专项取证和反馈 |
| `NotPIGX` | 报告未命中的综合端证据；已确认的 AURA 框架库按框架分支处理，其他项目结束综合端分流 |
| `IncompleteCandidate`，有 Aura 专有证据且明确前端规范或正式审查 | `aura-web-review`，按选定模式报告缺项，正式盘点时使用 `-ReviewCandidate` |
| 其他 `IncompleteCandidate` | 仅报告命中和缺失证据，不自动进入开发 |

脚本推荐是启发式提示。按用户要完成的动作和对象判断。检查 diff 交由审查入口按变更范围选交付，报警详情故障走业务诊断，地图页面拆分建议走结构咨询。全屏、拖拽、分屏、聚合等词需要视频或地图场景证据。联邦和预构建专项按实际目标分流，综合审查中提及联邦仍按综合审查处理。混合请求分别保留各动作的授权和范围。

检查范围只限某项配置时，按该范围检查、修复明确问题并复检。明确要求只修复某项配置时，按实施流程处理该项。

## 技能安装检查

分流前核对当前可用技能列表。缺失时说明技能名、用途及受影响流程，询问是否安装；未经明确授权不得安装，也不得假称已调用。拒绝或安装失败后，地图/视频可交由 Web 技能按本地规范降级；Web 主技能或模块联邦检查缺失则暂停对应分支。

正式页面、菜单和按钮交由 Web 技能的菜单权限流程处理；管理端写入仍须明确授权及目标环境、运行时凭据、租户、父菜单信息。
