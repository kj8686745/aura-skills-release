# Aura Skills Release

这是福信富通技能的发布仓库，只包含已审核、可供安装的技能版本；开发源码、未发布变更和维护资料不在此仓库中。

## 安装

安装指定技能到 Codex 的全局技能目录：

```powershell
npx skills add kj8686745/aura-skills-release --skill <技能名称> --global --yes --agent codex
```

安装全部已发布技能到 Codex：

```powershell
npx skills add kj8686745/aura-skills-release --skill '*' --global --yes --agent codex
```

更新已安装技能：

```powershell
npx skills update <技能名称> --global --yes
```

## 技能管理

查看已安装的技能：

```powershell
npx skills list
```

删除多个技能：

```powershell
npx skills remove <技能名称> to-spec diagnosing-bugs
```

删除全局安装的技能：

```powershell
npx skills remove -g <技能名称>
```

跳过确认直接删除：

```powershell
npx skills remove -y <技能名称>
```

删除所有技能：

```powershell
npx skills remove --all
```

## 已发布技能

| 技能 | 版本 | 说明 |
| --- | --- | --- |
| aura-base-backend-development | 0.1.0-draft | 按 AURA 基础编码规范新增或修改后端业务代码；已有系统先识别现状与调用方，再按接口、数据、权限、事务和兼容规则收敛；框架现成能力的具体用法另由能力包提供。 |
| aura-base-interface-development | 0.1.0-draft | 为 AURA 前后端或服务间协作设计接口契约、按业务模块编写接口文档并准备联调时使用；具体页面和服务内部实现分别交由前后端开发技能。 |
| aura-base-interface-review | 0.1.0-draft | 审查已开发一段时间的 AURA 前后端或服务间接口，识别现状、调用方和统一契约差异，输出可执行的调整顺序与验证结论；不替代新接口设计、后端实现或真实联调。 |
| aura-module-federation-check | 1.1.0 | 自动识别 Vue 3 + Vite 项目属于 PIGX 综合端、模块联邦生产端或消费端，并检查 PIGX 综合端的模块联邦身份、依赖、Vite 配置、shared singleton、运行时外壳、i18n、样式、静态资源和构建产物。模块联邦配置由 Web 开发技能实现，本技能提供改前基线、改后复检与对外接入说明；首版生产端或消费端仅报告类型和证据。 |
| aura-web-develop | 1.3.0 | 按 PIGX 模块联邦综合端规范开发和评审 Vue 3 + Vite + TypeScript 业务，涵盖 CRUD、接口、菜单权限、组件复用与模块联邦实现；适用于 aura-pigx-cli nexus 项目及其业务远程模块。 |
| aura-web-project-router | 1.0.3 | 对当前框架未知的 Vue 3 + Vite 项目进行轻量只读识别，并在 PIGX 综合端开发、CRUD、路由菜单、权限、地图、视频或模块联邦配置时分流到对应技能；不实现业务，也不接管普通 Vue/Vite、React 或非 PIGX 项目。 |
| fmap-2d | 1.0.6 | 公司 2D 地图业务开发规范技能，指导 Agent 在 Vue 3 + Vite 项目中接入 @fxft/ui-plus，并使用 FxftMap 完成地图页面、点位聚合、轨迹回放、热力图、绘制和 GeoJSON 渲染。 |
| fxft-video | 2.0.6 | 在 Vue 3 + Vite 项目中使用 @fxft/ui-plus 的 FxftWebVideo 与 FxftWebMultiVideo 实现直播、回放、点播、PTZ、分屏、拖拽、多选和通道管理。 |

发布清单见 [manifest.json](./manifest.json)。
