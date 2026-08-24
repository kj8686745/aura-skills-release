# FxftMultiVideoPlayer 多路基础页面模板

适用于多路分屏播放、监控大屏或多窗口直播页面。

```vue
<template>
  <div class="multi-video-page">
    <FxftMultiVideoPlayer
      ref="multiRef"
      :split="split"
      :videos="videos"
      :autoplay="true"
      play-mode="live"
      decoder-path="/jessibucaPro/decoder-pro-simd.js"
      @ready="onReady"
      @selected="onSelected"
      @play="onPlay"
      @error="onError"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";

const multiRef = ref<any>(null);
const split = ref(4);

const videos = ref([
  { uuid: "camera-001", id: 1, name: "一路", url: "ws://example.com/live/ch01" },
  { uuid: "camera-002", id: 2, name: "二路", url: "ws://example.com/live/ch02" },
  { uuid: "camera-003", id: 3, name: "三路", url: "ws://example.com/live/ch03" },
  { uuid: "camera-004", id: 4, name: "四路", url: "ws://example.com/live/ch04" },
]);

const onReady = (instance: unknown) => {
  console.log("多路播放器已创建", instance);
};

const onSelected = (payload: any) => {
  console.log("选中窗口", payload.index, payload.uuid, payload.url);
};

const onPlay = (payload: any) => {
  console.log("窗口开始播放", payload.index, payload.uuid);
};

const onError = (payload: any) => {
  console.error("窗口播放异常", payload.index, payload.uuid, payload.value?.message);
};

const changeSplit = (nextSplit: number | string) => {
  split.value = nextSplit as number;
  multiRef.value?.arrangeWindow?.(nextSplit);
};

const playSelectedWindow = (url: string) => {
  multiRef.value?.playWindow?.(undefined, url);
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

- `split` 支持 `1`、`2`、`3`、`4`、`3-1`、`4-1`。
- `videos` 中建议提供稳定 `uuid`，方便后续拖拽和业务映射。
- `playWindow()` 不传窗口时默认播放当前选中窗口。
