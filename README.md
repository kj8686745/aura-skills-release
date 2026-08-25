# Aura Skills Release

这是福信富通技能的发布仓库，只包含已审核、可供安装的技能版本；开发源码、未发布变更和维护资料不在此仓库中。

## 安装

使用 npx skills 安装指定技能：

```powershell
npx skills add kj8686745/aura-skills-release --skill <技能名称> --global --yes
```

更新已安装技能：

```powershell
npx skills update <技能名称> --global --yes
```

## 已发布技能

| 技能 | 版本 | 说明 |
| --- | --- | --- |
| aura-pigx-web-develop | 1.2.1 | 按最新版 PIGX 模块联邦（综合端）规范完成 Vue 3 + Vite + TypeScript 业务开发、页面模式选型、接口封装、路由菜单、模块联邦、组件复用、样式与静态资源适配，并支持需求描述、截图、PRD、HTML 原型、Figma 和 Apifox 联调场景。用于开发、修改、评审或验收 aura-pigx-cli nexus 项目及其业务远程模块。 |
| fmap-2d | 1.0.2 | 公司 2D 地图业务开发规范技能，指导 Agent 在 Vue 3 + Vite 项目中接入 @fxft/ui-plus，并使用 FxftMap 完成地图页面、点位聚合、轨迹回放、热力图、绘制和 GeoJSON 渲染。 |

发布清单见 [manifest.json](./manifest.json)。
