# FxftMap 地图组件指南

`FxftMap` 是 `@fxft/ui-plus` 提供的 2D 地图组件，封装了底图切换、点位与聚合、轨迹回放、热力图、交互绘制、API 直接绘制和 GeoJSON 渲染能力。

## 基础用法

```vue
<template>
  <FxftMap
    ref="mapRef"
    v-bind="mapInitOptions"
    @load="onMapLoad"
  />
</template>

<script setup lang="ts">
import { ref } from "vue";

const mapRef = ref<any>(null);

const mapInitOptions = {
  center: { lon: 119.3052, lat: 26.07 },
  zoom: 12,
  minZoom: 3,
  maxZoom: 18,
  baseLayers: ["gaodeVec", "gaodeImg"],
  defaultLayer: "gaodeVec",
  showLayerSwitcher: true,
  showMapTool: true,
};

const onMapLoad = (mapInstance: unknown) => {
  console.log("地图加载完成", mapInstance);
};
</script>
```

## 高频 Props

| 属性名 | 类型 | 说明 |
|---|---|---|
| `center` | `{ lon: number; lat: number }` | 地图初始中心点 |
| `zoom` | `number` | 地图初始缩放级别 |
| `minZoom` | `number` | 最小缩放级别 |
| `maxZoom` | `number` | 最大缩放级别 |
| `baseLayers` | `string[]` | 可切换底图列表 |
| `defaultLayer` | `string` | 默认底图 |
| `showLayerSwitcher` | `boolean` | 是否显示底图切换器 |
| `showMapTool` | `boolean` | 是否显示地图工具栏 |

## 高频 Events

| 事件名 | 说明 |
|---|---|
| `load` | 地图初始化完成 |
| `map-click` | 地图点击 |
| `view-change` | 视图变化，例如缩放、移动、旋转 |
| `marker-click` | 点位点击 |
| `draw-end` | 交互绘制结束 |
| `draw-edit` | 绘制编辑结束 |
| `track-progress` | 轨迹播放进度变化 |
| `track-marker-click` | 轨迹点点击 |
| `track-stopped` | 轨迹停止 |
| `tool-action` | 地图工具栏动作透出 |
| `rotation-change` | 地图旋转角变化 |

## 高频 Exposes

通过 `mapRef.value?.方法名?.()` 调用。

| 方法 | 说明 |
|---|---|
| `flyTo(options)` | 地图飞行定位 |
| `addPoint(pointsOrPoint, options?, layerName?)` | 添加单点或多点，支持聚合与弹窗 |
| `clearPointById(id, layerName?)` | 按 id 删除点位 |
| `setPointLayerVisible(layerName?, visible?)` | 隐藏/显示整个普通或聚合点位图层；不清空点位和聚合索引 |
| `setPointVisible(id, visible?, layerName?)` | 按稳定点位 id 隐藏/显示 marker；隐藏点不参与当前聚合数量 |
| `updatePointSymbol(id, symbol, layerName?)` | 按稳定点位 id 更新 marker 图标；不移除点位、不改变聚合总数据 |
| `playTrack(markerList, options?, layerName?)` | 创建轨迹实例 |
| `playTrackStart()` | 开始轨迹播放 |
| `pauseTrack()` | 暂停轨迹播放 |
| `showTrackLayer()` | 显示轨迹图层及轨迹内部标注，包括轨迹线、起点、终点、当前位置点、轨迹点 marker 和底线；不重绘、不重置进度 |
| `hideTrackLayer(options?)` | 隐藏轨迹图层及轨迹内部标注，默认先暂停播放；不清空轨迹、不重绘、不重置进度。传 `{ pause: false }` 可只隐藏不暂停 |
| `stopTrack()` | 停止轨迹播放 |
| `restartTrack()` | 重播轨迹 |
| `setTrackSpeed(speed)` | 设置轨迹倍速 |
| `setTrackProgress(progress)` | 按距离进度设置播放位置，范围建议 `0~100` |
| `setTrackTime(timeValue)` | 按时间定位轨迹位置 |
| `clearTrack()` | 清空轨迹实例 |
| `setHeat(points, options?, layerName?)` | 设置并显示热力图 |
| `startDraw(type, layerName?)` | 开始交互绘制 |
| `stopDraw()` | 停止当前绘制 |
| `setDrawSymbol(symbol, layerName?)` | 更新指定绘制图层后续交互绘制与 GeoJSON 回显的点、线、面样式 |
| `initDraw(geojson, options?, layerName?)` | 初始化或重新回显可编辑 GeoJSON，`options.symbol` 可同步指定样式 |
| `callDrawTool(action, data)` | 控制绘制工具条 |
| `drawByType(type, data, options?, layerName?)` | 统一 API 绘制入口 |
| `renderGeoJSON(geojson, options?, layerName?)` | 渲染 GeoJSON |
| `clearLayer(layerName)` | 清空指定图层 |
| `removeLayer(layerName)` | 移除指定图层 |

## 图层显示隐藏

图层显示/隐藏只控制可见性，不应和点位增删混用。必须使用公开 API：

```typescript
mapRef.value?.setPointLayerVisible?.("deviceMarkerLayer", false);
mapRef.value?.setPointLayerVisible?.("deviceMarkerLayer", true);
```

只隐藏某一类点位时，按稳定点位 id 调用单点显隐；隐藏的 marker 保留在图层与索引中，但不参与当前聚合数量：

```typescript
const setAlarmPointsVisible = (points: Array<{ id: string; alarm: boolean }>, visible: boolean) => {
  points
    .filter((point) => point.alarm)
    .forEach((point) => mapRef.value?.setPointVisible?.(point.id, visible, "deviceMarkerLayer"));
};
```

> 注意：`clearLayer(layerName)` 是清空图层数据，不是隐藏图层。业务页面不得访问 `_layer`、`_clusterLayerMap` 等私有字段。

## 点位与聚合

点位常用字段：

| 字段 | 说明 |
|---|---|
| `id` | 点位唯一标识，必须稳定 |
| `lon` / `lng` / `longitude` | 经度 |
| `lat` / `latitude` | 纬度 |
| `icon` | 图标 URL |
| `markerWidth` / `markerHeight` | 图标尺寸 |
| `customData` | 业务透传数据 |
| `infoWindow` | 信息窗配置 |
| `events` | marker 事件 |

`addPoint` 常用 options：

| 字段 | 说明 |
|---|---|
| `cluster` | 是否启用聚合 |
| `clear` | 添加前是否清空当前图层 |
| `enableClick` | 是否透出 `marker-click` |
| `clusterMarkerRanges` | 聚合图标分级配置 |
| `maxClusterZoom` | 聚合显示的最大缩放层级；地图缩放层级大于该值时不再聚合，自动显示散点。该配置只控制聚合行为，不控制整个图层显隐 |
| `maxClusterRadius` | 当前缩放级别下的屏幕像素半径，不是固定公里数；底层按 `resolution × maxClusterRadius` 换算地图距离 |
| `forceRenderOnMoving` | 地图移动过程中实时重绘聚合画布，避免点位贴在屏幕上漂移 |
| `forceRenderOnZooming` | 地图缩放过程中实时重绘聚合画布，避免聚合点与底图错位 |
| `forceRenderOnRotating` | 地图旋转过程中实时重绘聚合画布，避免聚合点与底图错位 |
| `animation` | 聚合中心过渡动画；全部 marker 可能被隐藏时建议设为 `false`，规避空范围动画跳动和 `getMin` 错误 |
| `infoWindow` | 默认信息窗配置 |
| `clusterInfoWindow` | 聚合点信息窗配置 |
| `events` | 给 marker 统一绑定事件 |

点位增删建议：

- 单个或少量点位移除时，优先使用 `clearPointById(id, layerName)`，不要为了移除一个点反复 `clearLayer + addPoint` 整层重绘。
- 新增点位时可使用 `addPoint(points, { clear: false, ...options }, layerName)` 追加到已有图层。
- 数据源整体刷新、筛选条件整体变化或聚合配置重建时，才使用 `clear: true` 或 `clearLayer(layerName)`。
- `clearPointById` 的 `id` 必须和添加点位时的点位 `id` 完全一致，聚合图层同样按该 id 删除子点。

### 统一聚合与增量同步

- 同一业务实体只进入一个聚合图层。报警、在线、离线等状态使用 `updatePointSymbol` 切换图标，或使用 `setPointVisible` 控制分类显隐，不要再叠加第二个报警聚合层。
- 点位 id 必须使用真正唯一的业务主键。资产场景优先使用 `assetId`；当设备 ID 或设备编码可能被多个资产复用时，不得优先使用设备字段。
- 首次地图加载与接口数据到达必须汇入同一个幂等同步入口，避免同一批点位以 `clear: false` 追加两次。
- 维护 `id → 数据快照`：新增 id 才追加，缺失 id 才调用 `clearPointById`，坐标或状态变化才更新同 id 点位。按钮显隐不请求、不清空、不重建图层。
- 分类按钮关闭后，对应 marker 应退出当前聚合数量；所有分类都关闭时地图无点且聚合数量为 0，恢复后数量不翻倍。

### 聚合半径为什么不是固定公里

`maxClusterRadius` 的单位是屏幕像素。底层在每个 zoom 下按地图分辨率换算，因此同一个 `220` 在不同缩放级别对应不同的实际距离。这样放大地图时聚合会自然散开，缩小时会自然合并。

如果业务明确要求固定公里范围，不应直接把公里数填入 `maxClusterRadius`；需要根据当前纬度与 zoom 动态换算像素，并在 `view-change` 后更新聚合配置。普通监控地图优先保留像素语义，以获得稳定的视觉密度和更低的重建成本。

### 缩放时聚合点移动或漂移

现象：缩放、拖动或旋转时底图先变化，聚合点短暂贴在屏幕原位置，结束后再跳到新位置。

解决：创建聚合层时启用交互过程实时重绘；这会重绘当前聚合结果，不会清空 marker 或重建业务数据。

```typescript
mapRef.value?.addPoint?.(
  points,
  {
    cluster: true,
    clear: false,
    maxClusterRadius: 220,
    maxClusterZoom: 17,
    forceRenderOnMoving: true,
    forceRenderOnZooming: true,
    forceRenderOnRotating: true,
    animation: false,
  },
  "deviceMarkerLayer"
);
```

其中 `forceRenderOnZooming` 解决缩放错位，`forceRenderOnMoving` 解决拖动错位，`forceRenderOnRotating` 解决旋转错位。若业务允许所有 marker 隐藏，设置 `animation: false` 可避免从 0 个可见点恢复时聚合中心动画读取空范围。

## 轨迹回放

轨迹点常用字段：

| 字段 | 说明 |
|---|---|
| `lon` / `lng` / `longitude` | 经度 |
| `lat` / `latitude` | 纬度 |
| `time` | 时间戳或时间值 |

`playTrack` 常用 options：

| 字段 | 说明 |
|---|---|
| `speed` | 初始播放速度 |
| `playNow` | 是否创建后立即播放 |
| `fit` | 是否自动缩放到轨迹范围 |
| `mapUnFollow` | 地图是否不跟随轨迹点 |
| `lineWidth` / `lineColor` / `lineOpacity` | 轨迹线样式 |
| `baseLine` / `baseLineWidth` / `baseLineColor` | 底线样式 |
| `icon` | 运动点图标 |
| `startIcon` / `endIcon` | 起点和终点图标 |
| `showMarker` | 是否显示每一个轨迹点 marker |
| `colorStrategy` | 按轨迹点属性给线段着色 |

注意：有效轨迹点少于 2 个时不应创建轨迹。

轨迹显示/隐藏优先使用 `showTrackLayer()` / `hideTrackLayer()`，不要用 `clearTrack()` 或重新 `playTrack()` 代替显隐。`hideTrackLayer()` 会同时隐藏轨迹线、起点、终点、当前位置点、轨迹点 marker 和底线，默认暂停播放但不清空轨迹、不重绘、不重置进度；传 `{ pause: false }` 可只隐藏不暂停。

`track-progress` 的 `payload` 常用字段：

| 字段 | 说明 |
|---|---|
| `distanceProgress` | 距离进度百分比，范围通常为 `0~100` |
| `timeProgress` | 时间进度百分比，范围通常为 `0~100` |
| `currentTime` | 当前播放时间戳，没有有效时间时通常为 `0` |
| `startTime` | 轨迹起始时间戳，没有有效时间时通常为 `0` |
| `endTime` | 轨迹结束时间戳，没有有效时间时通常为 `0` |
| `totalDistance` | 轨迹总距离 |
| `nowDistance` | 当前已播放距离 |
| `playState` | 播放状态，例如 `running`、`paused`、`finished` |

页面展示时间轴时优先使用 `timeProgress`、`currentTime`、`startTime`、`endTime`；按距离控制位置时使用 `distanceProgress`。

## 热力图

热力点支持：

```typescript
type HeatPoint = [number, number, number] | { lon: number; lat: number; value: number };
```

`setHeat` 常用 options：

| 字段 | 说明 |
|---|---|
| `radius` | 热力半径 |
| `blur` | 模糊程度 |
| `max` | 热力值上限 |
| `minOpacity` | 最小透明度 |
| `gradient` | 颜色梯度映射 |

## 绘制与 GeoJSON

常用方法：

| 方法 | 说明 |
|---|---|
| `startDraw(type, layerName?)` | 交互绘制点、线、圆、矩形、多边形 |
| `setDrawSymbol(symbol, layerName?)` | 设置指定绘制图层后续交互绘制与 GeoJSON 回显的样式 |
| `initDraw(geojson, options?, layerName?)` | 初始化或重新回显可编辑 GeoJSON；`options` 支持 `clear`、`fitView`、`flyTo` 和 `symbol` |
| `callDrawTool("setToolVisible", boolean)` | 显示或隐藏绘制工具条 |
| `callDrawTool("setToolBarlist", string[])` | 设置工具条可见绘制类型 |
| `drawByType(type, data, options?, layerName?)` | 通过结构化数据或 GeoJSON 字符串绘制 |
| `renderGeoJSON(geojson, options?, layerName?)` | 渲染 GeoJSON |

`renderGeoJSON` 常用 options：

| 字段 | 说明 |
|---|---|
| `clear` | 渲染前是否清空 |
| `fitView` | 是否自动定位到图形范围 |
| `flyTo` | 是否以飞行动画定位 |

### 动态绘制样式

当业务外部状态改变而图形样式需要同步变化时，统一通过公开 API 更新。未产生图形时，先设置下一次交互绘制的样式；已有图形时，使用新样式重新回显已有 GeoJSON。

```typescript
const getDrawSymbol = () => ({
  lineColor: "#2563eb",
  lineWidth: 2,
  polygonFill: "#2563eb",
  polygonOpacity: 0.28,
});

// 未绘制：影响后续交互绘制。
mapRef.value?.setDrawSymbol?.(getDrawSymbol(), "editableDrawLayer");

// 已有图形：同步刷新当前可编辑图形的样式和视图。
mapRef.value?.initDraw?.(
  geojson,
  { clear: true, fitView: true, symbol: getDrawSymbol() },
  "editableDrawLayer"
);
```

> 业务页面不得访问或修改 `_options`、`_drawTool`、`_geometry` 等私有字段。`setDrawSymbol` 与 `initDraw` 的 `symbol` 参数是动态样式的唯一业务调用入口。

## 注意事项

1. 通过 `ref` 调用方法前，要确认 `mapRef.value` 已存在。
2. `playTrack` 至少传入 2 个有效轨迹点。
3. `setTrackProgress(progress)` 建议传入 `0~100`。
4. `callDrawTool` 是工具条控制能力，调用前确认 action 和 data。
5. 传入非法 GeoJSON 或非法坐标数据时，图形可能无法渲染。
