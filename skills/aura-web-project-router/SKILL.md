---
name: aura-web-project-router
description: 对当前框架未知的 Vue 3 + Vite 项目进行轻量只读识别，并在 PIGX 综合端开发、CRUD、路由菜单、权限、地图、视频或模块联邦配置时分流到对应技能；不实现业务，也不接管普通 Vue/Vite、React 或非 PIGX 项目。
---

# Aura PIGX 项目分流

当前版本：`1.0.3`。

仅在 Vue/Vite 项目框架未知且需要业务开发、路由菜单、权限或模块联邦处理时做只读识别与分流。不实现业务、不修改项目、不调用管理端 API。

## 首次调用提示

简要说明将识别项目并选择技能；已有路径和需求时直接推进。询问用法时才读取 [使用说明](USAGE.md)。

## 识别

运行 `scripts/detect-pigx-project.ps1 -ProjectPath <项目路径> -TaskDescription <用户需求> -Json`，核对四项证据：

- `src/config/moduleFederationBaseConfig.ts` 的 `currentRemoteConfig`。
- `src/hooks/moduleFederation.ts` 的 `exposeModules`。
- `src/utils/moduleFederationRegistry.ts` 的 `getModuleFederationLoader`。
- `vite.config.*` 的 `@module-federation/vite` / `federation()`。

不得用项目名、目录名、旧经验或单一模块联邦特征代替。

## 分流

| 结果 / 需求 | 后续动作 |
| --- | --- |
| `Integrated`，普通业务 | `aura-web-develop` |
| 综合端，2D 地图、点位、聚合、轨迹、热力、绘制、GeoJSON | Web 技能 + `fmap-2d` |
| 综合端，视频、回放、点播、PTZ、分屏、拖拽 | Web 技能 + `fxft-video` |
| 综合端，remote/expose/manifest/shared/远程菜单/运行时配置 | Web 技能实现；`aura-module-federation-check` 做改前基线和改后复检 |
| 综合端，仅模块联邦检查、审计或排查 | 只加载 `aura-module-federation-check` |
| `NotPIGX` | 报告未命中证据并退出 |
| `IncompleteCandidate` | 报告命中和缺失证据；仅用户明确要求建设为综合端时进入 Web 技能 |

## 技能安装检查

分流前核对当前可用技能列表。缺失时说明技能名、用途及受影响流程，询问是否安装；未经明确授权不得安装，也不得假称已调用。拒绝或安装失败后，地图/视频可交由 Web 技能按本地规范降级；Web 主技能或模块联邦检查缺失则暂停对应分支。

正式页面、菜单和按钮交由 Web 技能的菜单权限流程处理；管理端写入仍须明确授权及目标环境、运行时凭据、租户、父菜单信息。
