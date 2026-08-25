# FxftMap 绘制与 GeoJSON 模板

适用于电子围栏、行政区边界、园区边界、手动画区和后端 GeoJSON 渲染。

```vue
<template>
  <div class="draw-map-page">
    <FxftMap
      ref="mapRef"
      v-bind="mapInitOptions"
      @load="onMapLoad"
      @draw-end="onDrawEnd"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";

const mapRef = ref<any>(null);
const fenceDrawLayer = "fenceDrawLayer";
const districtGeoJSONLayer = "districtGeoJSONLayer";

const mapInitOptions = {
  center: { lon: 119.3052, lat: 26.07 },
  zoom: 12,
  baseLayers: ["gaodeVec", "gaodeImg"],
  defaultLayer: "gaodeVec",
  showLayerSwitcher: true,
  showMapTool: true,
};

const isValidGeoJSON = (geojson: any) => {
  return Boolean(geojson && typeof geojson === "object" && typeof geojson.type === "string");
};

const getDrawSymbol = () => ({
  lineColor: "#2563eb",
  lineWidth: 2,
  polygonFill: "#2563eb",
  polygonOpacity: 0.28,
});

const onMapLoad = () => {
  mapRef.value?.callDrawTool?.("setToolBarlist", ["Point", "LineString", "Polygon"]);
  mapRef.value?.callDrawTool?.("setToolVisible", true);
};

const startPolygonDraw = () => {
  mapRef.value?.startDraw?.("polygon", fenceDrawLayer);
};

// 外部状态变化且当前尚未产生图形时，更新后续交互绘制样式。
const applyNextDrawSymbol = () => {
  mapRef.value?.setDrawSymbol?.(getDrawSymbol(), fenceDrawLayer);
};

// 外部状态变化且已有可编辑图形时，以新样式重新回显。
const renderEditableGeoJSON = (geojson: unknown) => {
  if (!isValidGeoJSON(geojson)) {
    mapRef.value?.clearLayer?.(fenceDrawLayer);
    return;
  }

  mapRef.value?.initDraw?.(
    geojson,
    { clear: true, fitView: true, symbol: getDrawSymbol() },
    fenceDrawLayer
  );
};

const stopDraw = () => {
  mapRef.value?.stopDraw?.();
};

const onDrawEnd = (payload: unknown) => {
  console.log("绘制结束", payload);
  // 这里仅接收绘制结果；保存接口请拆到单独业务方法。
};

const drawPointByApi = () => {
  mapRef.value?.drawByType?.(
    "point",
    {
      id: "api-point-1",
      lon: 119.326,
      lat: 26.064,
    },
    {},
    fenceDrawLayer
  );
};

const renderDistrictGeoJSON = (geojson: unknown) => {
  if (!isValidGeoJSON(geojson)) {
    mapRef.value?.clearLayer?.(districtGeoJSONLayer);
    return;
  }

  mapRef.value?.renderGeoJSON?.(
    geojson,
    {
      clear: true,
      fitView: true,
      flyTo: true,
    },
    districtGeoJSONLayer
  );
};

const clearDrawLayer = () => {
  mapRef.value?.clearLayer?.(fenceDrawLayer);
};

const clearGeoJSONLayer = () => {
  mapRef.value?.clearLayer?.(districtGeoJSONLayer);
};
</script>

<style scoped>
.draw-map-page {
  width: 100%;
  height: 100%;
  min-height: 480px;
}
</style>
```

## 使用要点

- 交互绘制使用 `startDraw`。
- 外部状态影响绘制样式时：未绘制图形用 `setDrawSymbol` 设置后续样式，已有图形用 `initDraw` 携带 `symbol` 重新回显。
- API 直接绘制使用 `drawByType`。
- GeoJSON 渲染使用 `renderGeoJSON`。
- 渲染前至少校验 `geojson.type`。
- 绘制和 GeoJSON 使用不同业务图层名，避免互相覆盖。
- 不访问 `_options`、`_drawTool`、`_geometry` 等地图或绘制工具私有字段。
