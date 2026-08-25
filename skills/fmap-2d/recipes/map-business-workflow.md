# 地图业务开发流程配方

## 1. 识别需求

先判断需求属于哪个场景：

- 基础地图。
- 点位与聚合。
- 轨迹回放。
- 热力图。
- 交互绘制。
- API 绘制。
- GeoJSON 渲染。
- 多场景组合。

## 2. 依赖检查

必须检查：

- `@fxft/ui-plus` 是否安装。
- `FxftUiPlusResolver` 是否配置。
- 项目是否已有全量注册。

缺依赖时必须先授权再安装。

## 3. 模板匹配

按场景读取：

- 基础地图：`templates/fxft-map-basic-page.md`
- 点位聚合：`templates/fxft-map-points.md`
- 轨迹回放：`templates/fxft-map-track.md`
- 热力图：`templates/fxft-map-heat.md`
- 绘制/GeoJSON：`templates/fxft-map-draw-geojson.md`

## 4. 数据适配

按 `recipes/map-data-normalization.md`：

- 坐标统一为 `lon` / `lat`。
- 点位 id 稳定。
- 轨迹点不少于 2 个。
- 热力点包含权重。
- GeoJSON 结构合法。

## 5. 地图组件接入

统一使用：

```vue
<FxftMap ref="mapRef" v-bind="mapInitOptions" />
```

根据业务挂载事件：

- `@load`
- `@map-click`
- `@marker-click`
- `@track-progress`
- `@draw-end`

## 6. 图层管理

为每类业务图层定义稳定名称：

```typescript
const deviceMarkerLayer = "deviceMarkerLayer";
const vehicleTrackLayer = "vehicleTrackLayer";
const alarmHeatLayer = "alarmHeatLayer";
```

刷新数据时使用：

```typescript
mapRef.value?.clearLayer?.(deviceMarkerLayer);
```

## 7. 事件处理

事件回调只做轻量处理：

```typescript
const onMarkerClick = (event: any) => {
  const row = event?.customData;
  if (!row) return;
  openDeviceDetail(row);
};
```

复杂逻辑拆成业务方法或组合式函数。

## 8. 验证与交付

按 `checklists/validation.md` 执行，并在交付中说明：

- 依赖状态。
- Resolver 状态。
- 使用的 FxftMap 能力。
- 数据适配方式。
- 验证结果和未验证风险。
