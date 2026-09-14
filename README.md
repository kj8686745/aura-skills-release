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
| aura-module-federation-check | 1.0.2 | 自动识别 Vue 3 + Vite 项目属于 PIGX 综合端、模块联邦生产端或消费端，并检查 PIGX 综合端的模块联邦身份、依赖、Vite 配置、shared singleton、运行时外壳、i18n、样式、静态资源和构建产物。模块联邦配置由 Web 开发技能实现，本技能提供改前基线、改后复检与对外接入说明；首版生产端或消费端仅报告类型和证据。 |
| aura-web-develop | 1.2.22 | 按最新版 PIGX 模块联邦（综合端）规范完成 Vue 3 + Vite + TypeScript 业务开发、CRUD、接口封装、正式菜单与按钮权限、组件复用、统一视觉风格与样式资源适配。模块联邦配置由本技能实现，并串联检查技能做改前基线与改后复检；用于 aura-pigx-cli nexus 项目及其业务远程模块。 |
| aura-web-project-router | 1.0.2 | 对当前框架未知的 Vue 3 + Vite 项目进行轻量只读识别，并在 PIGX 综合端开发、CRUD、路由菜单、权限、地图、视频或模块联邦配置时分流到对应技能；不实现业务，也不接管普通 Vue/Vite、React 或非 PIGX 项目。 |
| fmap-2d | 1.0.5 | 公司 2D 地图业务开发规范技能，指导 Agent 在 Vue 3 + Vite 项目中接入 @fxft/ui-plus，并使用 FxftMap 完成地图页面、点位聚合、轨迹回放、热力图、绘制和 GeoJSON 渲染。 |
| fxft-video | 2.0.5 | 在 Vue 3 + Vite 项目中使用 @fxft/ui-plus 的 FxftWebVideo 与 FxftWebMultiVideo 实现直播、回放、点播、PTZ、分屏、拖拽、多选和通道管理。 |

发布清单见 [manifest.json](./manifest.json)。
