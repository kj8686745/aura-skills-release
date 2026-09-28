---
name: fmap-2d
description: 公司 2D 地图业务开发规范技能，指导 Agent 在 Vue 3 + Vite 项目中接入 @fxft/ui-plus，并使用 FxftMap 完成地图页面、点位聚合、轨迹回放、热力图、绘制和 GeoJSON 渲染。
metadata:
  version: "1.0.6"
  type: project-development-standard
  project: fmap-2d
  stack: Vue 3 / Vite / TypeScript / @fxft/ui-plus / FxftMap
---

# fmap-2d 2D 地图业务开发规范

使用 `@fxft/ui-plus` 的 `FxftMap` 实现地图业务。首次调用简要说明；用户问用法时才读取 [使用说明](USAGE.md)。

## 接入底线

- 检查目标项目 `package.json`、lock 文件及实际组件库版本。所用能力的最低版本查 [安装与版本要求](references/ui-plus-installation.md)；版本不足不得生成不兼容调用。
- 安装或升级必须获得用户授权，沿用项目包管理器。默认 `FxftUiPlusResolver` 按需引入；已有全量注册则沿用，避免覆盖现有配置。
- 必须使用 `FxftMap` 公开 API，不复制已有能力，不得自行引入地图 SDK 绕过组件库；例外须用户明确要求。访问底层实例须公开能力确实不足且用户确认。
- 坐标归一为 `{ lon, lat }` 并过滤无效数据；点位使用真正唯一且稳定的业务 ID，同一实体只进入一个聚合图层，更新按 ID 增量同步。
- 普通选点使用 `map-click` + `addPoint` 回显唯一默认 marker，不启用绘制流程。其它场景细则按下表读取。

## 按场景读取

只读命中的章节与模板，多场景去重；不固定加载全套资料。

| 场景 | 必读资料 |
| --- | --- |
| 首次接入、框架适配 | [项目画像](references/project-profile.md)、[接入检查](checklists/pre-development.md) |
| 安装、版本或 Resolver | [安装规则](references/ui-plus-installation.md)、[接入步骤](recipes/install-and-resolver.md) |
| 地图业务实现或修改 | [业务规则](references/map-business-rules.md) 中对应场景章节 |
| 新建地图基础页面 | [基础模板](templates/fxft-map-basic-page.md) |
| 点位、聚合、HTML Marker | [点位模板](templates/fxft-map-points.md)、[数据归一化](recipes/map-data-normalization.md) |
| 地图选点 | [组件指南](references/map-component-guide.md)“地图选点”、[数据归一化](recipes/map-data-normalization.md) |
| 轨迹 / 热力图 | [轨迹模板](templates/fxft-map-track.md) / [热力模板](templates/fxft-map-heat.md)、[数据归一化](recipes/map-data-normalization.md) |
| 绘制、动态样式、GeoJSON | [绘制模板](templates/fxft-map-draw-geojson.md) |
| Props、Events、Exposes 或组件调用 | [组件指南](references/map-component-guide.md) 对应章节，核对公开 API |
| 交付验证 | [实现清单](checklists/implementation.md)、[验证清单](checklists/validation.md) 中本次适用项 |

## 验证与交付

地图事件保持轻量，业务逻辑拆到业务方法或组合式函数。坐标系确认后才考虑纠偏，资源性能配置按真实场景选择，具体见业务规则。

按项目能力完成构建、类型和浏览器交互验证。需要其它技能时先核对可用列表，只在任务需要且可用时调用；页面验证使用当前可用浏览器工具，不假设特定插件已安装。

交付说明实际改动、依赖/Resolver、数据适配与验证结果；仅列确实存在的限制和未验证项，不机械输出所有资料名或空栏目。
