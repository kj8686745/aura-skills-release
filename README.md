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
| fmap-2d | 1.0.4 | 公司 2D 地图业务开发规范技能，指导 Agent 在 Vue 3 + Vite 项目中接入 @fxft/ui-plus，并使用 FxftMap 完成地图页面、点位聚合、轨迹回放、热力图、绘制和 GeoJSON 渲染。 |
| fxft-video | 1.0.1 | 公司视频业务开发规范技能，指导 Agent 在 Vue 3 + Vite 项目中接入 @fxft/ui-plus，并使用 FxftVideoPlayer 与 FxftMultiVideoPlayer 完成单路监控、多路分屏、录像回放、点播、PTZ、全屏和拖拽换位。 |

发布清单见 [manifest.json](./manifest.json)。
