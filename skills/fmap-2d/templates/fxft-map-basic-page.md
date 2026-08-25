# FxftMap 基础地图页面模板

适用于只需要初始化地图、展示底图切换和地图工具栏的页面。

```vue
<template>
  <div class="map-page">
    <FxftMap
      ref="mapRef"
      v-bind="mapInitOptions"
      @load="onMapLoad"
      @map-click="onMapClick"
    />
  </div>
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

const onMapClick = (event: unknown) => {
  console.log("地图点击", event);
};

const flyToDefaultCenter = () => {
  mapRef.value?.flyTo?.({
    center: mapInitOptions.center,
    zoom: mapInitOptions.zoom,
  });
};
</script>

<style scoped>
.map-page {
  width: 100%;
  height: 100%;
  min-height: 480px;
}
</style>
```

## 使用要点

- 页面容器必须有明确高度，否则地图无法正常展示。
- `center` 使用 `{ lon, lat }`。
- 业务需要定位时优先调用 `flyTo`。
