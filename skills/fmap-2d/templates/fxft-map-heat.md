# FxftMap 热力图模板

适用于告警密度、客流密度、能耗密度等热力展示。

```vue
<template>
  <div class="heat-map-page">
    <FxftMap
      ref="mapRef"
      v-bind="mapInitOptions"
      @load="onMapLoad"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";

type RawHeatPoint = {
  lng?: number;
  lon?: number;
  longitude?: number;
  lat?: number;
  latitude?: number;
  value?: number;
  count?: number;
};

type HeatPoint = [number, number, number];

const mapRef = ref<any>(null);
const alarmHeatLayer = "alarmHeatLayer";

const mapInitOptions = {
  center: { lon: 119.3052, lat: 26.07 },
  zoom: 12,
  baseLayers: ["gaodeVec", "gaodeImg"],
  defaultLayer: "gaodeVec",
  showLayerSwitcher: true,
  showMapTool: true,
};

const getNumberValue = (...values: Array<unknown>) => {
  const value = values.find((item) => Number.isFinite(Number(item)));
  return value === undefined ? undefined : Number(value);
};

const normalizeHeatPoint = (item: RawHeatPoint): HeatPoint | null => {
  const lon = getNumberValue(item.lon, item.lng, item.longitude);
  const lat = getNumberValue(item.lat, item.latitude);
  const value = getNumberValue(item.value, item.count);

  if (lon === undefined || lat === undefined || value === undefined) return null;
  if (lon < -180 || lon > 180 || lat < -90 || lat > 90) return null;

  return [lon, lat, value];
};

const renderHeat = (rawList: RawHeatPoint[]) => {
  const heatPoints = rawList
    .map(normalizeHeatPoint)
    .filter((item): item is HeatPoint => Boolean(item));

  if (!heatPoints.length) {
    mapRef.value?.clearLayer?.(alarmHeatLayer);
    return;
  }

  mapRef.value?.setHeat?.(
    heatPoints,
    {
      radius: 18,
      max: 100,
      blur: 10,
      minOpacity: 0.15,
      gradient: {
        0.2: "#3b82f6",
        0.4: "#22c55e",
        0.6: "#eab308",
        0.8: "#f97316",
        1.0: "#ef4444",
      },
    },
    alarmHeatLayer
  );
};

const onMapLoad = () => {
  // 替换为真实热力接口数据
  const rawHeatList: RawHeatPoint[] = [];
  renderHeat(rawHeatList);
};

const clearHeat = () => {
  mapRef.value?.clearLayer?.(alarmHeatLayer);
};
</script>

<style scoped>
.heat-map-page {
  width: 100%;
  height: 100%;
  min-height: 480px;
}
</style>
```

## 使用要点

- 热力点必须包含经度、纬度和权重值。
- 无有效数据时先清理图层并展示空状态。
- 热力图用独立图层名，方便刷新与清理。
