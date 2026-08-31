# 地图业务规则

## 依赖规则

- 任何 2D 地图业务开始前，必须检查 `@fxft/ui-plus`。
- 缺少依赖时，必须先获得用户授权再安装。
- 优先使用 `FxftUiPlusResolver` 按需引入组件和样式。

## 组件规则

- 地图页面必须使用 `FxftMap`。
- 不重复实现 `FxftMap` 已提供的点位、聚合、轨迹、热力、绘制、GeoJSON 能力。
- 不绕过组件库自行引入地图 SDK，除非用户明确要求并说明原因。
- 优先使用 `FxftMap` 公开 Exposes，不直接访问底层地图实例。

## 坐标规则

统一在适配层转换为：

```typescript
{
  lon: number;
  lat: number;
}
```

后端返回以下字段时需要兼容：

- 经度：`lon`、`lng`、`longitude`
- 纬度：`lat`、`latitude`

无效坐标必须过滤：

- 经度不是有限数字。
- 纬度不是有限数字。
- 经度超出 `-180~180`。
- 纬度超出 `-90~90`。

## 图层命名规则

图层名必须有业务语义，避免使用 `layer1`、`testLayer`、`markerLayer` 等泛名称。

推荐示例：

- `deviceMarkerLayer`
- `vehicleTrackLayer`
- `alarmHeatLayer`
- `fenceDrawLayer`
- `districtGeoJSONLayer`

## 点位规则

- 点位必须有稳定 `id`。
- 点位 `id` 必须优先使用真正唯一的业务主键；资产地图优先使用 `assetId`，设备 ID/编码可能复用时不得作为主键。
- 不要在每次刷新时用当前时间随机生成 id。
- 点位业务数据放入 `customData`，不要散落在事件闭包中。
- 大量点位优先开启聚合。
- 同一实体只进入一个聚合图层；报警、在线、离线等 PNG 状态通过 `updatePointSymbol` 或 `setPointVisible` 表达，PNG/HTML 表现或坐标变化通过 `updatePointMarker` 更新，禁止重复叠加多个聚合层。
- HTML Marker 使用同一稳定点位在原聚合图层中的透明普通 Marker 代理参与聚合；禁止另建孤立 HTML 图层或重复添加同一业务实体。
- 动态事件（例如 SOS）提供有效坐标时，以事件坐标更新匹配到的稳定点位；业务只传 `{ lon, lat }`，由组件转换底层坐标格式。
- HTML Marker 切回图片后必须继续保留原稳定 id、显隐状态和聚合关系。
- 单个或少量点位移除时优先使用 `clearPointById(id, layerName)`，避免 `clearLayer + addPoint` 造成整层重绘和卡顿。
- 新增点位时优先使用 `addPoint(points, { clear: false, ...options }, layerName)` 追加点位。
- 坐标、状态或图标变化时只更新同 id 点位；删除时只调用 `clearPointById`，不得每次数据范围变化都整层重建。
- 只有数据源彻底替换或需要重建聚合配置时，才使用 `clear: true` 或 `clearLayer(layerName)` 做整层同步。
- 地图加载和初始接口数据必须汇入同一个幂等同步入口，避免同一批点位以 `clear: false` 重复追加。
- 整层显隐使用 `setPointLayerVisible`；分类显隐使用 `setPointVisible`。隐藏 marker 不删除数据，但不参与当前聚合数量。

## 聚合规则

- `maxClusterRadius` 的单位是屏幕像素，不是固定公里数；实际地图距离随 zoom 和纬度分辨率变化。
- `maxClusterZoom` 控制超过哪个缩放层级后散点显示，不控制图层显隐。
- 缩放、移动、旋转时聚合点贴屏幕或漂移，设置 `forceRenderOnZooming: true`、`forceRenderOnMoving: true`、`forceRenderOnRotating: true`。
- 所有 marker 可能被隐藏时建议设置 `animation: false`，避免恢复聚合时中心跳动或底层读取空范围出现 `getMin` 错误。
- 圆形聚合背景默认使用 `clusterTextAlign: 'center'` 与 `clusterTextVerticalAlign: 'middle'`；`clusterTextDx`、`clusterTextDy` 只用于不规则背景图的视觉中心微调。
- 分类按钮切换不请求、不清空、不重建图层；所有分类关闭时聚合数量应为 0，恢复后数量不得翻倍。

## 轨迹规则

- 轨迹回放至少需要 2 个有效点。
- 无效坐标先过滤，过滤后不足 2 个点时展示空状态或提示。
- 需要展示时间轴时，优先使用 `track-progress` 的 `currentTime`、`startTime`、`endTime`。
- 需要按距离控制进度时，使用 `distanceProgress` 和 `setTrackProgress`。
- 轨迹图层显示/隐藏优先使用 `showTrackLayer()` / `hideTrackLayer()`，不要通过 `clearTrack()` 或重新 `playTrack()` 实现显隐。
- 隐藏轨迹图层时默认应暂停播放，但不能清空轨迹、重绘轨迹或重置进度。

## 热力图规则

- 热力点必须包含经度、纬度和权重值。
- 权重值必须是有效数字。
- 空数据或全量无效数据应先给出空状态，不调用 `setHeat`。
- 热力图图层使用独立业务图层名，便于清理。

## 绘制与 GeoJSON 规则

- 交互绘制使用 `startDraw`。
- API 直接绘制使用 `drawByType`。
- GeoJSON 渲染使用 `renderGeoJSON`。
- GeoJSON 渲染前必须校验结构至少具备 `type` 字段。
- 绘制结束事件 `draw-end` 中只做数据接收和派发，复杂保存逻辑拆到业务方法中。

## 事件规则

- 地图事件回调中不堆叠复杂业务逻辑。
- 事件回调只做轻量转换、状态更新或调用业务方法。
- 需要请求后端时，单独封装 API 方法，避免事件处理器直接写大段请求逻辑。

## 验证规则

交付前至少说明以下验证结果：

- `@fxft/ui-plus` 是否存在。
- `FxftUiPlusResolver` 是否配置。
- 页面是否使用 `FxftMap`。
- 是否没有引入其它地图 SDK。
- 坐标、轨迹、热力、GeoJSON 是否做了有效性过滤。
