---
name: fmap-2d
description: 公司 2D 地图业务开发规范技能，指导 Agent 在 Vue 3 + Vite 项目中接入 @fxft/ui-plus，并使用 FxftMap 完成地图页面、点位聚合、轨迹回放、热力图、绘制和 GeoJSON 渲染。
metadata:
  version: "1.0.4"
  type: project-development-standard
  project: fmap-2d
  stack: Vue 3 / Vite / TypeScript / @fxft/ui-plus / FxftMap
---
# fmap-2d 2D 地图业务开发规范

你是公司 2D 地图业务开发规范执行器。后续任何涉及 2D 地图的需求，都必须优先使用 `@fxft/ui-plus` 提供的 `FxftMap` 组件完成，不得绕过组件库重复封装地图 SDK。

## 首次调用提示

当前会话首次命中本技能时，简要说明：它负责用 `FxftMap` 实现地图业务；需要项目路径、地图数据/坐标系和目标能力；先核验 `@fxft/ui-plus` 版本，使用 1.0.36 新能力时要求 `>= 1.0.36`。示例为“新增设备地图，展示点位聚合和轨迹回放”“使用批量轨迹和 GeoJSON 上传”。同一会话后续不重复；用户询问“怎么用”“帮助”或“示例”时读取并输出 [使用说明](USAGE.md) 的相关部分。

## 重要：先读哪些文件

| 任务类型 | 必读文件 |
|---|---|
| 任意 2D 地图业务 | `references/project-profile.md`、`references/map-business-rules.md`、`checklists/pre-development.md` |
| 安装或接入组件库 | `references/ui-plus-installation.md`、`recipes/install-and-resolver.md` |
| 地图基础页面 | `templates/fxft-map-basic-page.md`、`references/map-component-guide.md` |
| 点位、Marker、聚合 | `templates/fxft-map-points.md`、`references/map-component-guide.md`、`recipes/map-data-normalization.md` |
| 地图选点、位置选择 | `references/map-component-guide.md` 的“地图选点”章节、`recipes/map-data-normalization.md` |
| 轨迹回放 | `templates/fxft-map-track.md`、`references/map-component-guide.md`、`recipes/map-data-normalization.md` |
| 热力图 | `templates/fxft-map-heat.md`、`references/map-component-guide.md`、`recipes/map-data-normalization.md` |
| 交互绘制、API 绘制、GeoJSON | `templates/fxft-map-draw-geojson.md`、`references/map-component-guide.md` |
| 交付前验证 | `checklists/implementation.md`、`checklists/validation.md` |

## 技能目录结构

```text
fmap-2d/
├── SKILL.md
├── README.md
├── USAGE.md
├── DESIGN.md
├── references/
│   ├── project-profile.md
│   ├── ui-plus-installation.md
│   ├── map-component-guide.md
│   └── map-business-rules.md
├── templates/
│   ├── README.md
│   ├── fxft-map-basic-page.md
│   ├── fxft-map-points.md
│   ├── fxft-map-track.md
│   ├── fxft-map-heat.md
│   └── fxft-map-draw-geojson.md
├── checklists/
│   ├── pre-development.md
│   ├── implementation.md
│   └── validation.md
├── recipes/
│   ├── install-and-resolver.md
│   ├── map-business-workflow.md
│   └── map-data-normalization.md
└── scripts/
    └── validate-skill.ps1
```

## 强制工作流

1. **识别 2D 地图需求**：凡是涉及地图展示、设备点位、轨迹、热力、区域绘制、GeoJSON、地图事件交互的任务，都按本技能执行。
2. **先检查目标项目依赖和版本**：读取目标项目 `package.json` 与 lock 文件，确认是否存在并实际解析 `@fxft/ui-plus` 版本；点位分类显隐与图标更新需要 `>= 1.0.34`，动态绘制/GeoJSON 样式及 1.0.36 的批量轨迹、图层视图、图片导出能力需要 `>= 1.0.36`。
3. **版本不足或未安装时必须授权**：不得静默安装或升级；先说明所需版本、会修改依赖与 lock 文件，用户明确授权后才使用项目现有包管理器通过公司私有 registry 安装或升级。
4. **复用包管理器**：根据 lock 文件或项目脚本判断使用 npm、pnpm 或 yarn，禁止混用包管理器。
5. **检查按需引入配置**：检查 `vite.config.ts` 是否已有 `unplugin-vue-components`、`unplugin-auto-import` 和 `FxftUiPlusResolver`。
6. **优先按需引入**：默认使用 `FxftUiPlusResolver` 按需引入组件和样式；只有目标项目已有全量注册约定时，才沿用全量注册。
7. **必须使用 FxftMap**：地图业务页面必须使用 `<FxftMap>` 或 `<fxft-map>`；不得自行引入高德、百度、Mapbox、OpenLayers 等 SDK 绕过组件库。
8. **先匹配模板**：按业务场景选择基础地图、点位聚合、轨迹、热力、绘制/GeoJSON 模板，再结合真实业务调整。
9. **核对公开 API**：通过 `ref` 调用地图方法时，只使用 `FxftMap` 公开的 Exposes；1.0.36 批量轨迹仅使用 `playBatchTracks`、`playBatchTracksStart`、`pauseBatchTracks`、`stopBatchTracks`、`setBatchTracksSpeed`、`setBatchTracksProgress`、`setBatchTrackPointsVisible`、`clearBatchTracks`，图层视图使用 `fitLayer`、`flyToLayer`，导出使用 `exportImage`。
10. **数据先归一化**：后端坐标字段必须适配为稳定的 `lon` / `lat`，轨迹、热力、GeoJSON 在渲染前先过滤无效数据。
11. **事件保持轻量**：地图事件回调只做派发或轻量状态更新，复杂业务逻辑拆到组合式函数或业务方法中。
12. **交付前验证**：按 `checklists/validation.md` 检查依赖、resolver、构建、页面行为和交付格式。

## 当前项目硬性约束

- 不允许自行引入高德、百度、Mapbox、OpenLayers 等地图 SDK 绕过 `FxftMap`，除非用户明确要求并说明原因。
- 不允许复制实现 `FxftMap` 已提供的底图切换、地图工具栏、点位、聚合、轨迹、热力、绘制、GeoJSON 渲染能力。
- 不在未取得用户授权的情况下安装 `@fxft/ui-plus` 或任何新依赖。
- 私有 registry 地址仅用于安装命令，不写入业务代码。
- 优先使用组件公开 API，不直接访问底层地图实例；只有 `FxftMap` 暴露能力无法满足且用户确认时，才考虑底层实例。
- 交互绘制或 GeoJSON 回显需要随外部状态切换样式时，必须使用 `setDrawSymbol` 和 `initDraw` 的 `symbol` 参数；不得修改绘制工具或图形对象的私有字段。
- 图层命名必须有业务语义，例如 `deviceMarkerLayer`、`vehicleTrackLayer`、`alarmHeatLayer`。
- 点位 id 必须稳定，不得每次刷新都临时生成导致 diff、清理和点击回调失效。
- 普通位置选择必须通过 `map-click` 获取坐标，并使用 `addPoint` 回显唯一 marker；不得为单点选址启用 `startDraw('point')`、`draw-end` 或 `initDraw`。未要求自定义视觉时不得传入图标和尺寸配置，使用组件默认 marker。
- 点位 id 优先使用真正唯一的业务主键（资产场景优先 `assetId`）；设备 ID 或设备编码不保证唯一时不得作为点位主键。
- 同一批业务点只进入一个聚合图层；报警、在线、离线等状态通过 marker 图标和单点显隐表达，不得用多个聚合层重复渲染同一实体。
- 大批量点位变化必须按稳定 id 做增量新增、删除和更新；不得因按钮显隐、树勾选或普通刷新反复整层 `clear: true` 重建。
- 聚合层缩放、移动或旋转时出现点位贴屏幕、漂移，必须启用 `forceRenderOnZooming`、`forceRenderOnMoving`、`forceRenderOnRotating`；全部 marker 隐藏后恢复若出现中心跳动或 `getMin` 错误，同时设置 `animation: false`。
- 轨迹回放至少需要 2 个有效点；热力点必须包含权重值；GeoJSON 渲染前必须校验结构。
- `gaodeCorrection` 只能在业务数据坐标系已确认且确有纠偏需求时开启，不得凭经验设置；`devicePixelRatio`、`drawOnce`、`drawGeojsonActions` 也必须按实际交互与设备性能选择。

## 与其它技能协作

- `/vueuse-functions`：涉及防抖节流、异步状态、浏览器 API、定时器时先调用。
- `/agent-browser`：涉及地图页面、交互、路由、样式和控制台验证时调用。
- `/planning-with-files-junmoxiao`：复杂地图业务或多页面地图功能开发时用于持久化规划。

## 交付格式

完成 2D 地图任务后按以下结构回复：

1. **完成内容**：列出新增/修改文件。
2. **使用的技能资料**：列出命中的 `templates/`、`references/`、`recipes/`、`checklists/`。
3. **依赖检查结果**：说明 `@fxft/ui-plus` 是否已存在，是否安装过依赖，若未安装说明是否获得授权。
4. **组件接入方式**：说明使用按需引入还是全量注册，`FxftUiPlusResolver` 是否配置。
5. **地图实现说明**：说明使用的 `FxftMap` 能力，例如点位、聚合、轨迹、热力、绘制、GeoJSON。
6. **数据适配说明**：说明坐标、轨迹、热力、GeoJSON 的归一化和过滤方式。
7. **验证结果**：列出构建、类型检查、浏览器页面验证结果；未验证项必须说明原因。
8. **剩余风险**：列出依赖、私有 registry、底图资源、真实后端数据、浏览器环境等风险。
