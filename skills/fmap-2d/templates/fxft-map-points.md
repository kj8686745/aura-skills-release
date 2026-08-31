# FxftMap 点位与聚合模板

适用于设备点位、告警点位、人员点位等地图展示场景。

```vue
<template>
  <div class="map-page">
    <FxftMap
      ref="mapRef"
      v-bind="mapInitOptions"
      @load="onMapLoad"
      @marker-click="onMarkerClick"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";

type RawDevice = {
  id: string | number;
  assetId?: string | number;
  name: string;
  lng?: number;
  lon?: number;
  longitude?: number;
  lat?: number;
  latitude?: number;
  status?: string;
};

type MapPoint = {
  id: string | number;
  lon: number;
  lat: number;
  customData: RawDevice;
};

const mapRef = ref<any>(null);
const deviceMarkerLayer = "deviceMarkerLayer";

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

const normalizeDevicePoint = (item: RawDevice): MapPoint | null => {
  const lon = getNumberValue(item.lon, item.lng, item.longitude);
  const lat = getNumberValue(item.lat, item.latitude);

  if (lon === undefined || lat === undefined) return null;
  if (lon < -180 || lon > 180 || lat < -90 || lat > 90) return null;

  return {
    id: item.assetId || item.id,
    lon,
    lat,
    customData: item,
  };
};

const renderDevicePoints = (rawList: RawDevice[]) => {
  const points = rawList
    .map(normalizeDevicePoint)
    .filter((item): item is MapPoint => Boolean(item));

  mapRef.value?.addPoint?.(
    points,
    {
      cluster: true,
      clear: false,
      enableClick: true,
      markerWidth: 36,
      markerHeight: 36,
      // 聚合显示的最大缩放层级；超过该层级后自动散点
      maxClusterZoom: 17,
      // 单位为屏幕像素，不是固定公里数
      maxClusterRadius: 220,
      // 交互过程实时重绘，避免聚合点贴屏幕或与底图错位
      forceRenderOnMoving: true,
      forceRenderOnZooming: true,
      forceRenderOnRotating: true,
      // 支持全部 marker 隐藏时关闭中心过渡，规避空范围动画跳动
      animation: false,
      // 圆形聚合背景使用真实水平、垂直居中；不规则背景再用 dx/dy 微调
      clusterTextAlign: "center",
      clusterTextVerticalAlign: "middle",
      clusterTextDx: 0,
      clusterTextDy: 0,
      clusterMarkerRanges: [
        { min: 0, width: 40, height: 40, textSize: 12 },
        { min: 10, width: 46, height: 46, textSize: 12 },
      ],
    },
    deviceMarkerLayer
  );
};

const onMapLoad = async () => {
  // 替换为真实接口数据
  const deviceList: RawDevice[] = [];
  renderDevicePoints(deviceList);
};

const onMarkerClick = (event: any) => {
  const device = event?.customData;
  if (!device) return;
  console.log("点位点击", device);
};

const clearDevicePoints = () => {
  mapRef.value?.clearLayer?.(deviceMarkerLayer);
};

const removeDevicePoint = (id: string | number) => {
  mapRef.value?.clearPointById?.(id, deviceMarkerLayer);
};

const appendDevicePoints = (rawList: RawDevice[]) => {
  renderDevicePoints(rawList);
};

const setDeviceLayerVisible = (visible: boolean) => {
  mapRef.value?.setPointLayerVisible?.(deviceMarkerLayer, visible);
};

const setDeviceVisible = (id: string | number, visible: boolean) => {
  mapRef.value?.setPointVisible?.(id, visible, deviceMarkerLayer);
};

const updateDeviceIcon = (id: string | number, markerFile: string) => {
  mapRef.value?.updatePointSymbol?.(id, { markerFile }, deviceMarkerLayer);
};

const showHtmlDeviceMarker = (
  id: string | number,
  longitude: number,
  latitude: number,
  content: HTMLElement
) => {
  mapRef.value?.updatePointMarker?.(
    id,
    {
      type: "html",
      coordinate: { lon: longitude, lat: latitude },
      content,
      horizontalAlignment: "middle",
      verticalAlignment: "middle",
      dx: 0,
      dy: 0,
    },
    deviceMarkerLayer
  );
};

const restoreImageDeviceMarker = (
  id: string | number,
  longitude: number,
  latitude: number,
  markerFile: string
) => {
  mapRef.value?.updatePointMarker?.(
    id,
    {
      type: "image",
      coordinate: { lon: longitude, lat: latitude },
      symbol: {
        markerFile,
        markerWidth: 36,
        markerHeight: 36,
      },
    },
    deviceMarkerLayer
  );
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

- 点位 `id` 必须稳定并真正唯一；资产场景优先使用 `assetId`，不要默认设备 ID/编码不会重复。
- 大量点位建议开启 `cluster: true`。
- 同一实体只进入一个聚合图层；普通 PNG 状态使用 `updatePointSymbol` 切换图标，PNG/HTML 表现或坐标更新使用 `updatePointMarker`，分类开关使用 `setPointVisible`。
- HTML Marker 复用原稳定 id 和原聚合图层，通过透明普通 Marker 代理参与聚合；不得另建 HTML 图层或重复点位。
- 动态事件坐标有效时，以事件 `{ lon, lat }` 更新同一点位；不要向业务代码暴露底层坐标类型。
- HTML `content` 优先使用可信 DOM 或静态模板，不拼接未经处理的用户输入。
- 维护 `id → 数据快照` 做增量同步：新增点只追加、删除点只调用 `clearPointById`、变化点只更新同 id；不要每次刷新全量 `clear: true`。
- 地图加载完成和初始接口返回必须调用同一个幂等同步入口，避免同一批点以 `clear: false` 追加两次。
- `maxClusterRadius` 是像素语义，实际公里数会随 zoom 变化。
- 缩放时聚合位置漂移时启用 `forceRenderOnZooming`；拖动、旋转分别启用 `forceRenderOnMoving`、`forceRenderOnRotating`。全部点可隐藏时同时设置 `animation: false`。
- 圆形聚合数字使用 `center` / `middle`；只有不规则背景才用 `clusterTextDx`、`clusterTextDy` 微调，并验证多位数仍居中。
- 点击事件可通过 `@marker-click` 处理，业务数据放在 `customData`。
