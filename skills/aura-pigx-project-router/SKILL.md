---
name: aura-pigx-project-router
description: 对当前框架未知的 Vue 3 + Vite 项目进行轻量只读识别，并在 PIGX 综合端开发、CRUD、路由菜单、权限或模块联邦配置时分流到对应 PIGX 技能；不实现业务，也不接管普通 Vue/Vite、React 或非 PIGX 项目。
---

# Aura PIGX 项目分流

当前版本：`1.0.0`。

仅在当前项目框架未知，且用户请求 Vue/Vite 开发、CRUD、路由、菜单、权限或模块联邦配置时使用。本技能只做只读识别和技能分流，不实现业务、不修改项目，也不调用管理端 API。

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

- `Integrated`：普通业务开发加载 `aura-pigx-web-develop`。
- `Integrated` 且需求涉及 `remote`、`expose`、`manifest`、远程菜单、`shared`、运行时入口或模块联邦配置：由 `aura-pigx-web-develop` 主导实现；修改前和完成后均加载 `aura-pigx-module-federation-check`，分别做基线与复检。
- `Integrated` 且需求仅为检查、审计、评审、验收或排查：只加载 `aura-pigx-module-federation-check`，不将其误分流为业务开发。
- `NotPIGX`：说明未命中证据并立即退出，不接管普通 Vue/Vite、React 或其他模块联邦项目。
- `IncompleteCandidate`：报告已命中和缺失证据，不进入 PIGX 开发流程；仅当用户明确要求将该项目建设为 PIGX 综合端时，才加载 `aura-pigx-web-develop` 继续规划和实现。

## 边界

分流到 Web 开发技能后，正式新业务页面、菜单入口或页面操作按钮由其菜单权限子流程处理。管理端真实写入仍需用户明确授权，并提供目标环境、运行时凭据、租户和父菜单定位信息。
