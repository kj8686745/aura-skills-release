# PIGX 综合端模块联邦规则矩阵

## 目录

1. [端类型识别](#一端类型识别)
2. [综合端身份](#二综合端身份)
3. [依赖与 Vite](#三依赖与-vite)
4. [运行时外壳](#四运行时外壳)
5. [综合端提供方](#五综合端提供方)
6. [综合端消费方](#六综合端消费方)
7. [后台菜单](#七后台菜单)
8. [资源与构建](#八资源与构建)
9. [首版边界](#九首版边界)

## 一、端类型识别

| 规则 | 级别 | 判定 |
|---|---|---|
| `MF-TYPE-001` | error | 项目目录或 `package.json` 无法读取。 |
| `MF-TYPE-002` | pass | 同时命中综合端基础配置、标准 expose、运行时注册表和 Vite federation。 |
| `MF-TYPE-003` | unsupported | 只命中生产端 exposes，返回退出码 `3`。 |
| `MF-TYPE-004` | unsupported | 只命中消费端 remotes/runtime，返回退出码 `3`。 |
| `MF-TYPE-005` | error | 同时命中非综合端的生产和消费特征，或证据不足，返回退出码 `2`。 |

显式 `-ProjectType` 只覆盖自动识别结果，不扩大首版支持范围。

## 二、综合端身份

| 规则 | 级别 | 判定 |
|---|---|---|
| `MF-ID-001` | error | 业务源码、环境变量、构建配置、根 README 或包信息仍包含模板占位名。规范文档目录不参与扫描。 |
| `MF-ID-002` | error | 缺少 `remoteName`、`remoteEntryName` 或 `systemId`。 |
| `MF-ID-003` | error | `remoteName` 不是 kebab-case，或 `remoteEntryName` 不是 lowerCamelCase。 |
| `MF-ID-004` | error | PostCSS/Tailwind scope 不等于 `aura-mf-remote-<remoteName>`。 |
| `MF-ID-005` | error | 启动缓存键前缀与 `systemId` 不一致。 |
| `MF-ID-006` | warning | `package.json.name` 与 `remoteName` 不一致。 |
| `MF-ID-007` | warning | 非根路径 `VITE_PUBLIC_PATH` 与 `remoteEntryName` 前缀不一致。 |
| `MF-ID-008` | manual | 部署环境内三个身份的唯一性无法仅靠单仓库确认。 |

`remoteName`、`remoteEntryName`、`systemId` 职责不同，不要求三者值完全相同。

## 三、依赖与 Vite

| 规则 | 级别 | 判定 |
|---|---|---|
| `MF-DEP-001` | error | 缺少 `@module-federation/vite` 或 `@module-federation/enhanced`。 |
| `MF-DEP-002` | error | 仍使用 `@originjs/vite-plugin-federation` 或 `vite-plugin-top-level-await`。 |
| `MF-DEP-003` | error | 明确配置的 Node 版本低于 `20.12.0`，或 pnpm 版本低于 `10.28.0`。 |
| `MF-VITE-001` | error | 缺少 federation 插件、当前容器名、`remoteEntry.js` 或 manifest。 |
| `MF-VITE-002` | error | Vue、Vue Router、Vue I18n、Pinia、Element Plus 未配置 singleton。 |
| `MF-VITE-003` | error | Element Plus 版本或 requiredVersion 未对齐 `2.14.3`。 |
| `MF-VITE-004` | error | 未禁用 Module Preload，或缺少远程预加载跳过插件。 |
| `MF-VITE-005` | warning | `bundleAllCSS` 不是 `false`，可能破坏 expose 级样式加载。 |

## 四、运行时外壳

| 规则 | 级别 | 判定 |
|---|---|---|
| `MF-RUNTIME-001` | error | 缺少综合端标准配置、注册表、远程入口、i18n、样式或 Element Provider 文件。 |
| `MF-RUNTIME-002` | error | 标准 `i18n/langs`、scoped Tailwind 或 runtime expose 缺失。 |
| `MF-RUNTIME-003` | error | 远程路由没有真实 `aura-mf-remote-scope` 根节点，或 Provider 未放在该根节点内部。 |
| `MF-RUNTIME-004` | error | 缺少加载失败隔离、重新加载、manifest/i18n/style 缓存刷新能力。 |
| `MF-RUNTIME-005` | error | 缺少运行时远程注册与入口标准化能力。 |

除标准外壳外，继续执行综合端提供方、消费方和菜单专项规则。

## 五、综合端提供方

| 规则 | 级别 | 判定 |
|---|---|---|
| `MF-PROVIDER-001` | error | expose key 重复、目标文件不存在或路径未使用 `./src/`。 |
| `MF-PROVIDER-002` | error | 页面 expose key 与 `./src/views/` 真实路径不能一一对应。 |
| `MF-PROVIDER-003` | error | 有业务 i18n 的页面未被 `i18nScanDirs` 覆盖。 |
| `MF-PROVIDER-004` | error | 构建 manifest 中缺少源码声明的 expose。 |

## 六、综合端消费方

| 规则 | 级别 | 判定 |
|---|---|---|
| `MF-CONSUMER-001` | error | `moduleFederationRemoteNames` 与运行时 entries 键不一致。 |
| `MF-CONSUMER-002` | error | 运行时 entry 未使用环境变量，或环境变量未在 `.env*` 声明。 |
| `MF-CONSUMER-003` | error | 远程入口前缀、本地代理路径和代理环境变量不一致。 |
| `MF-CONSUMER-004` | error | 源码直接导入远程模块，但编译期 remotes 未配置对应远程。 |
| `MF-CONSUMER-005` | error | 源码直接导入远程模块但缺少精确或通配 TypeScript 声明。 |
| `MF-CONSUMER-006` | error | 远程 Vue 组件静态默认导入，或动态导入未建立 `defineAsyncComponent` 边界。 |

动态菜单页面只需要运行时 entries，不应因为菜单加载而强制加入编译期 remotes；只有源码直接 import 的远程才执行 `MF-CONSUMER-004`。

## 七、后台菜单

| 规则 | 级别 | 判定 |
|---|---|---|
| `MF-MENU-001` | error | `componentPath` 缺少 `/remoteName/views/...` 或 `?type=moduleFederation`。 |
| `MF-MENU-002` | error | 本项目页面菜单无法映射到 expose，或外部远程未加入运行时清单。 |
| `MF-MENU-003` | manual | 后台“带参”开关无法从代码确认。 |

脚本自动扫描源码中的菜单字面量，也可通过 `-ComponentPath` 传入后台真实值。

## 八、资源与构建

| 规则 | 级别 | 判定 |
|---|---|---|
| `MF-RESOURCE-001` | warning | 源码出现硬编码 `/assets/` 或 CSS 根路径资源。 |
| `MF-RESOURCE-002` | warning | 导入图片、字体、视频等资源，但文件中未使用 `getStaticResourceUrl`。 |
| `MF-RESOURCE-003` | warning | 业务源码硬编码带 IP 的 HTTP(S) 地址。 |
| `MF-BUILD-001` | warning | 未提供 manifest 且 `dist/mf-manifest.json` 不存在，需要执行构建验证。 |
| `MF-BUILD-002` | error | 已存在构建目录或显式 manifest 时，缺少 `remoteEntry.js`、manifest 或标准 expose。 |
| `MF-BUILD-003` | manual | 独立运行、宿主加载、i18n、样式、资源请求和失败隔离需要浏览器验证。 |

资源扫描用于发现候选项。CSS import、外部 CDN 或明确经过模块联邦转换的代码应结合上下文复核。

## 九、首版边界

以下内容只预留独立项目处理器接口，不在 `1.0.0` 给出合规结论：

- 非 PIGX 综合端项目中的生产端业务规则。
- 非 PIGX 综合端项目中的消费端业务规则。
- 多仓库部署环境中的身份唯一性和 Nginx 配置。

PIGX 综合端自身的 exposes、remotes、类型声明、远程 Vue 组件和菜单路径均属于首版检查范围。
