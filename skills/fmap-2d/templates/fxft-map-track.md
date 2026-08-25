# FxftMap 轨迹回放模板

适用于车辆、人员、设备移动轨迹回放。

```vue
<template>
  <div class="track-map-page">
    <FxftMap
      ref="mapRef"
      v-bind="mapInitOptions"
      @load="onMapLoad"
      @track-progress="onTrackProgress"
      @track-stopped="onTrackStopped"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";

type RawTrackPoint = {
  lng?: number;
  lon?: number;
  longitude?: number;
  lat?: number;
  latitude?: number;
  time?: string | number | Date;
  speed?: number;
};

type TrackPoint = {
  lon: number;
  lat: number;
  time?: string | number | Date;
  speed?: number;
};

type TrackProgressPayload = {
  distanceProgress: number;
  timeProgress: number;
  currentTime: number;
  startTime: number;
  endTime: number;
  totalDistance: number;
  nowDistance: number;
  playState: string;
};

const mapRef = ref<any>(null);
const vehicleTrackLayer = "vehicleTrackLayer";
const trackProgress = ref({
  distanceProgress: 0,
  timeProgress: 0,
  currentTime: 0,
  startTime: 0,
  endTime: 0,
  totalDistance: 0,
  nowDistance: 0,
  playState: "idle",
});

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

const normalizeTrackPoint = (item: RawTrackPoint): TrackPoint | null => {
  const lon = getNumberValue(item.lon, item.lng, item.longitude);
  const lat = getNumberValue(item.lat, item.latitude);

  if (lon === undefined || lat === undefined) return null;
  if (lon < -180 || lon > 180 || lat < -90 || lat > 90) return null;

  return {
    lon,
    lat,
    time: item.time,
    speed: item.speed,
  };
};

const renderTrack = (rawTrackList: RawTrackPoint[]) => {
  const trackPoints = rawTrackList
    .map(normalizeTrackPoint)
    .filter((item): item is TrackPoint => Boolean(item));

  if (trackPoints.length < 2) {
    mapRef.value?.clearTrack?.();
    return;
  }

  mapRef.value?.playTrack?.(
    trackPoints,
    {
      speed: 100,
      playNow: false,
      fit: true,
      mapUnFollow: true,
      lineColor: "#3b82f6",
      baseLine: true,
      baseLineWidth: 8,
      showMarker: false,
      colorStrategy: {
        property: "speed",
        gradient: true,
        colorStops: [
          { value: 80, color: "#EF4444" },
          { value: 60, color: "#F97316" },
          { value: 40, color: "#EAB308" },
          { value: 0, color: "#22C55E" },
        ],
      },
    },
    vehicleTrackLayer
  );
};

const onMapLoad = () => {
  // 替换为真实轨迹接口数据
  const rawTrackList: RawTrackPoint[] = [];
  renderTrack(rawTrackList);
};

const onTrackProgress = (payload: Partial<TrackProgressPayload>) => {
  trackProgress.value = {
    distanceProgress: payload.distanceProgress ?? 0,
    timeProgress: payload.timeProgress ?? 0,
    currentTime: payload.currentTime ?? 0,
    startTime: payload.startTime ?? 0,
    endTime: payload.endTime ?? 0,
    totalDistance: payload.totalDistance ?? 0,
    nowDistance: payload.nowDistance ?? 0,
    playState: payload.playState ?? "idle",
  };
};

const onTrackStopped = () => {
  trackProgress.value = {
    distanceProgress: 0,
    timeProgress: 0,
    currentTime: 0,
    startTime: 0,
    endTime: 0,
    totalDistance: 0,
    nowDistance: 0,
    playState: "stopped",
  };
};

const startTrack = () => mapRef.value?.playTrackStart?.();
const pauseTrack = () => mapRef.value?.pauseTrack?.();
const stopTrack = () => mapRef.value?.stopTrack?.();
const setTrackSpeed = (speed: number) => mapRef.value?.setTrackSpeed?.(speed);
const setTrackProgress = (progress: number) => mapRef.value?.setTrackProgress?.(progress);
</script>

<style scoped>
.track-map-page {
  width: 100%;
  height: 100%;
  min-height: 480px;
}
</style>
```

## 使用要点

- 轨迹点少于 2 个时不要调用 `playTrack`。
- 轨迹点坐标必须先过滤。
- 播放控制使用 `playTrackStart`、`pauseTrack`、`stopTrack`、`setTrackSpeed`、`setTrackProgress`。
- `track-progress` 的 `payload` 不止距离进度，还包含时间进度、当前时间、起止时间、总距离、已播放距离和播放状态。
- 页面展示时间轴时优先使用 `timeProgress`、`currentTime`、`startTime`、`endTime`；按距离控制位置时使用 `distanceProgress`。
- `track-progress` 中优先更新进度状态，不写复杂业务逻辑。
