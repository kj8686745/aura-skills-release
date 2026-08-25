# 地图数据归一化配方

## 坐标归一化

后端经度字段可能为：

- `lon`
- `lng`
- `longitude`

后端纬度字段可能为：

- `lat`
- `latitude`

统一转换为：

```typescript
const getNumberValue = (...values: Array<unknown>) => {
  const value = values.find((item) => Number.isFinite(Number(item)));
  return value === undefined ? undefined : Number(value);
};

const normalizeCoordinate = (item: any) => {
  const lon = getNumberValue(item.lon, item.lng, item.longitude);
  const lat = getNumberValue(item.lat, item.latitude);

  if (lon === undefined || lat === undefined) return null;
  if (lon < -180 || lon > 180 || lat < -90 || lat > 90) return null;

  return { lon, lat };
};
```

## 点位归一化

```typescript
const normalizePoint = (item: any) => {
  const coordinate = normalizeCoordinate(item);
  if (!coordinate) return null;

  return {
    id: item.assetId || item.id,
    ...coordinate,
    customData: item,
  };
};
```

要求：

- `id` 使用稳定业务主键。
- 资产场景优先使用 `assetId`；只有确认设备 ID/编码全局唯一时才能用作点位主键。
- `customData` 保存原始业务数据。
- 无效点位过滤后再调用 `addPoint`。

## 轨迹归一化

```typescript
const normalizeTrackPoint = (item: any) => {
  const coordinate = normalizeCoordinate(item);
  if (!coordinate) return null;

  return {
    ...coordinate,
    time: item.time,
    speed: item.speed,
  };
};

const trackPoints = rawList
  .map(normalizeTrackPoint)
  .filter(Boolean);

if (trackPoints.length < 2) {
  // 展示空状态或清理轨迹
}
```

要求：

- 有效点不少于 2 个。
- 时间轴需求要保留 `time`。
- 分段着色需求要保留 `speed` 或对应属性。

## 热力点归一化

```typescript
const normalizeHeatPoint = (item: any): [number, number, number] | null => {
  const coordinate = normalizeCoordinate(item);
  const value = getNumberValue(item.value, item.count, item.weight);

  if (!coordinate || value === undefined) return null;

  return [coordinate.lon, coordinate.lat, value];
};
```

要求：

- 每个热力点必须包含权重值。
- 无有效热力点时先清理图层，不调用 `setHeat`。

## GeoJSON 校验

最低限度校验：

```typescript
const isValidGeoJSON = (geojson: any) => {
  return Boolean(geojson && typeof geojson === "object" && typeof geojson.type === "string");
};
```

建议进一步确认：

- `type` 是 `Feature`、`FeatureCollection` 或合法 Geometry 类型。
- `coordinates` 不为空。
- 坐标顺序为 `[lon, lat]`。

## 空数据处理

- 点位空：`clearLayer(deviceMarkerLayer)` 并展示空状态。
- 轨迹空：`clearTrack()` 并禁用播放按钮。
- 热力空：`clearLayer(alarmHeatLayer)`。
- GeoJSON 非法：`clearLayer(districtGeoJSONLayer)` 并提示数据异常。
