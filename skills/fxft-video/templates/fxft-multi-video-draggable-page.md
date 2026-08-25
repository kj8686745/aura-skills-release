# FxftMultiVideoPlayer 多路拖拽换位模板

适用于需要拖拽调整窗口顺序，并保持业务通道稳定映射的多路视频页面。

```vue
<template>
  <div class="multi-video-page">
    <FxftMultiVideoPlayer
      ref="multiRef"
      :split="4"
      :videos="videos"
      :autoplay="true"
      :draggable="true"
      decoder-path="/jessibucaPro/decoder-pro-simd.js"
      @selected="onSelected"
      @drop="onDrop"
      @error="onError"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";

type VideoItem = {
  uuid: string;
  id: number;
  name: string;
  url: string;
};

const multiRef = ref<any>(null);

const videos = ref<VideoItem[]>([
  { uuid: "camera-001", id: 1, name: "东门", url: "ws://example.com/live/east" },
  { uuid: "camera-002", id: 2, name: "西门", url: "ws://example.com/live/west" },
  { uuid: "camera-003", id: 3, name: "南门", url: "ws://example.com/live/south" },
  { uuid: "camera-004", id: 4, name: "北门", url: "ws://example.com/live/north" },
]);

const selectedUuid = ref("");

const onSelected = (payload: any) => {
  selectedUuid.value = payload.uuid || "";
};

const onDrop = (payload: any) => {
  const value = payload?.value || {};
  console.log("拖拽换位完成", value.fromUuid, value.toUuid);
  syncVideoOrderByUuid();
};

const syncVideoOrderByUuid = () => {
  const states = multiRef.value?.getWindowStates?.() || [];
  const order = states.map((item: any) => item.uuid).filter(Boolean);
  if (!order.length) return;

  const videoMap = new Map(videos.value.map((item) => [item.uuid, item]));
  videos.value = order
    .map((uuid: string) => videoMap.get(uuid))
    .filter(Boolean) as VideoItem[];
};

const onError = (payload: any) => {
  console.error("窗口播放异常", payload.uuid, payload.value?.message);
};
</script>

<style scoped>
.multi-video-page {
  width: 100%;
  height: 100%;
  min-height: 560px;
  background: #000;
}
</style>
```

## 使用要点

- 开启 `draggable` 后，窗口 `index` 会随 visual order 变化。
- 业务通道绑定必须优先使用 `uuid`。
- 监听 `drop` 后同步业务顺序，避免界面顺序和业务顺序不一致。
