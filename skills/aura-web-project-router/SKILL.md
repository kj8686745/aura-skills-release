---
name: aura-web-project-router
description: 对当前框架未知的 Vue 3 + Vite 项目进行轻量只读识别，并在 PIGX 综合端开发、CRUD、路由菜单、权限、地图、视频或模块联邦配置时分流到对应技能；不实现业务，也不接管普通 Vue/Vite、React 或非 PIGX 项目。
---

# Aura PIGX 项目分流

当前版本：`1.0.2`。

仅在当前项目框架未知，且用户请求 Vue/Vite 开发、CRUD、路由、菜单、权限或模块联邦配置时使用。本技能只做只读识别和技能分流，不实现业务、不修改项目，也不调用管理端 API。

## 首次调用提示

当前会话首次命中本技能时，简要说明：它只识别 PIGX 综合端并选择后续技能；用户可提供项目路径和需求；示例为“识别当前项目是否为 PIGX 综合端；我要新增设备 CRUD 页面”。同一会话后续不重复说明；用户询问“怎么用”“帮助”或“示例”时读取并输出 [使用说明](USAGE.md) 的相关部分。

## 识别

先运行：

```powershell
.\scripts\detect-pigx-project.ps1 -ProjectPath <项目路径> -TaskDescription <用户需求> -Json
```

脚本只检查四项 PIGX 综合端证据：

1. `src/config/moduleFederationBaseConfig.ts` 中的 `currentRemoteConfig`；
2. `src/hooks/moduleFederation.ts` 中的 `exposeModules`；
3. `src/utils/moduleFederationRegistry.ts` 中的 `getModuleFederationLoader`；
4. `vite.config.*` 中 `@module-federation/vite` 的 `federation()` 配置。

不得以项目名称、目录名、旧项目经验或单一模块联邦特征替代以上证据。

## 分流结果

- `Integrated`：普通业务开发加载 `aura-web-develop`。
- `Integrated` 且需求涉及 2D 地图、点位、聚合、轨迹回放、热力图、绘制或 GeoJSON：加载 `aura-web-develop` 和 `fmap-2d`。
- `Integrated` 且需求涉及监控视频、单路/多路播放、录像回放、点播、PTZ、分屏或拖拽换位：加载 `aura-web-develop` 和 `fxft-video`。
- `Integrated` 且需求涉及 `remote`、`expose`、`manifest`、远程菜单、`shared`、运行时入口或模块联邦配置：由 `aura-web-develop` 主导实现；修改前和完成后均加载 `aura-module-federation-check`，分别做基线与复检。
- `Integrated` 且需求仅为检查、审计、评审、验收或排查：只加载 `aura-module-federation-check`，不将其误分流为业务开发。
- `NotPIGX`：说明未命中证据并立即退出，不接管普通 Vue/Vite、React 或其他模块联邦项目。
- `IncompleteCandidate`：报告已命中和缺失证据，不进入 PIGX 开发流程；仅当用户明确要求将该项目建设为 PIGX 综合端时，才加载 `aura-web-develop` 继续规划和实现。

## 技能安装检查

准备加载任一分流结果前，必须以当前环境的可用技能列表检查其是否安装，包括 `aura-web-develop`、`fmap-2d`、`fxft-video` 和 `aura-module-federation-check`。缺失时列出技能名、用途和受影响流程，提示用户是否安装；未经明确授权不得安装，也不得假称已调用。用户拒绝或安装失败时，可降级的地图/视频/视觉流程交给 Web 技能按本地规范处理，Web 主技能或模块联邦检查等必需技能缺失时暂停对应分支。

## 边界

分流到 Web 开发技能后，正式新业务页面、菜单入口或页面操作按钮由其菜单权限子流程处理。管理端真实写入仍需用户明确授权，并提供目标环境、运行时凭据、租户和父菜单定位信息。

所有分流技能都要先检查是否安装。地图和视频专项不可用时先提示安装；用户拒绝或安装失败后才保留 `aura-web-develop` 降级处理。Web 主技能或模块联邦检查技能缺失时同样提示安装，不得直接跳过。
