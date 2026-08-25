# fmap-2d 使用说明

## 适用、调用与版本前提

用于 Vue 3 + Vite 项目的 2D 地图、点位、聚合、轨迹、热力、绘制和 GeoJSON。可根据需求自动触发，也可显式调用：`$fmap-2d <需求>`；不用于 3D 地图或要求绕过 `FxftMap` 的底层 SDK 重写。

请提供项目路径、地图数据样例、坐标系和目标能力。使用批量轨迹、`geojson-upload`、图层定位/导出等 1.0.36 API 前，必须确认 `@fxft/ui-plus >= 1.0.36`；版本不足时先说明升级会改动依赖与 lock 文件，获得用户明确授权后才升级。

可复制提示词：

- `在当前项目新增设备地图，展示点位聚合和告警筛选；先检查 @fxft/ui-plus 版本。`
- `实现车辆批量轨迹回放、倍速和进度控制；若版本不足 1.0.36，先告诉我再升级。`
- `新增 GeoJSON 围栏页面，支持上传、回显和导出图片；坐标系为 GCJ-02。`

## 何时使用

当用户需求出现以下关键词或意图时，优先使用本技能：

- 地图、二维地图、2D 地图
- 点位、Marker、聚合点、信息窗
- 轨迹、轨迹回放、车辆轨迹、人员轨迹
- 热力图、密度图
- 绘制、电子围栏、区域边界
- GeoJSON、行政区边界、园区边界
- `@fxft/ui-plus`、`FxftMap`、`FxftUiPlusResolver`

## 标准执行顺序

1. 读取 `SKILL.md`，确认任务类型和强制工作流。
2. 读取 `references/project-profile.md` 和 `references/map-business-rules.md`。
3. 检查目标项目 `package.json` 是否已安装 `@fxft/ui-plus`。
4. 检查目标项目 `vite.config.ts` 是否配置 `FxftUiPlusResolver`。
5. 按场景读取模板：
   - 基础地图：`templates/fxft-map-basic-page.md`
   - 点位聚合：`templates/fxft-map-points.md`
   - 轨迹回放：`templates/fxft-map-track.md`
   - 热力图：`templates/fxft-map-heat.md`
   - 绘制/GeoJSON：`templates/fxft-map-draw-geojson.md`
6. 按 `recipes/map-data-normalization.md` 做数据适配。
7. 按 `checklists/validation.md` 完成验证并交付。

## 依赖安装授权话术

如果目标项目缺少 `@fxft/ui-plus`，先回复用户：

> 当前项目未检测到 `@fxft/ui-plus`，2D 地图业务需要使用组件库提供的 `FxftMap`。是否授权我使用项目现有包管理器，通过公司私有 registry 安装该依赖？

获得授权后，再按项目包管理器执行对应命令。

## 常见任务用法

### 开发设备点位地图页面

读取：

- `references/ui-plus-installation.md`
- `references/map-component-guide.md`
- `references/map-business-rules.md`
- `templates/fxft-map-points.md`

重点验证：

- 点位 id 稳定。
- 资产场景优先使用 `assetId`，没有使用可能重复的设备 ID/编码作为点位主键。
- 坐标字段已归一化为 `lon` / `lat`。
- 使用单一聚合图层和 `addPoint(clear: false)` 做增量同步，图层名有业务语义。
- 整层显隐使用 `setPointLayerVisible`，分类显隐使用 `setPointVisible`，图标切换使用 `updatePointSymbol`。
- 缩放时若聚合点漂移，启用 `forceRenderOnZooming`；移动和旋转同步启用对应 `forceRenderOn*`，全部点可隐藏时设置 `animation: false`。
- 点击事件通过 `marker-click` 或 marker events 处理。

### 实现车辆轨迹回放

读取：

- `templates/fxft-map-track.md`
- `recipes/map-data-normalization.md`
- `references/map-component-guide.md`

重点验证：

- 有效轨迹点不少于 2 个。
- 时间字段可被解析。
- 使用 `playTrack`、`playTrackStart`、`pauseTrack`、`setTrackSpeed` 等公开方法。
- `track-progress` 只做轻量状态更新。

### 接入热力图

读取：

- `templates/fxft-map-heat.md`
- `recipes/map-data-normalization.md`

重点验证：

- 每个热力点包含经度、纬度和权重值。
- 使用 `setHeat(points, options, layerName)`。
- 清理时使用 `clearLayer`。

### 绘制行政区 GeoJSON 边界

读取：

- `templates/fxft-map-draw-geojson.md`
- `references/map-component-guide.md`

重点验证：

- GeoJSON 是合法 `Feature`、`FeatureCollection` 或几何对象。
- 使用 `renderGeoJSON` 或 `drawByType`。
- 图层命名清晰，支持清理和重绘。

## 不允许的做法

- 不检查依赖就直接写地图页面。
- 未经授权安装 `@fxft/ui-plus` 或其它依赖。
- 自行引入地图 SDK 绕过 `FxftMap`。
- 为点位、轨迹、热力、绘制重复实现组件库已有能力。
- 将公司私有 registry 写入业务代码。
