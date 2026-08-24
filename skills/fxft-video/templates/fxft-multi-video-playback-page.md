# FxftMultiVideoPlayer 多路录像/点播模板

适用于多个窗口同时播放录像或点播资源的页面。

```vue
<template>
  <div class="multi-video-page">
    <FxftMultiVideoPlayer
      ref="multiRef"
      :split="2"
      :videos="videos"
      :autoplay="true"
      play-mode="record"
      decoder-path="/jessibucaPro/decoder-pro-simd.js"
      @playback-timestamp="onPlaybackTimestamp"
      @playback-stats="onPlaybackStats"
      @playback-seek="onPlaybackSeek"
      @status-change="onStatusChange"
      @error="onError"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";

const multiRef = ref<any>(null);

const videos = ref([
  {
    uuid: "record-001",
    id: "record-001",
    name: "一号录像",
    url: "http://example.com/record/ch01.flv",
    playMode: "record",
    options: { controlType: "fullday", isPlaybackPauseClearCache: false },
  },
  {
    uuid: "vod-002",
    id: "vod-002",
    name: "二号点播",
    url: "http://example.com/vod/ch02.mp4",
    playMode: "vod",
  },
]);

const playbackTimeMap = ref<Record<string, string>>({});

const onPlaybackTimestamp = (payload: any) => {
  const uuid = payload.uuid || `index-${payload.index}`;
  const value = payload.value || {};
  const hour = String(value.hour ?? 0).padStart(2, "0");
  const min = String(value.min ?? 0).padStart(2, "0");
  const second = String(value.second ?? 0).padStart(2, "0");
  playbackTimeMap.value[uuid] = `${hour}:${min}:${second}`;
};

const onPlaybackStats = (payload: any) => {
  console.log("窗口录像统计", payload.uuid, payload.value);
};

const onPlaybackSeek = (payload: any) => {
  console.log("窗口进度拖动", payload.uuid, payload.value);
};

const onStatusChange = (payload: any) => {
  console.log("窗口状态变化", payload.uuid, payload.value);
};

const onError = (payload: any) => {
  console.error("窗口回放异常", payload.uuid, payload.value?.message);
};

const replayWindow = (uuid: string, url: string) => {
  multiRef.value?.playWindow?.(uuid, url, { playMode: "record" });
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

- 全局 `playMode` 可被每个 `videos` 项的 `playMode` 覆盖。
- 点播窗口使用 `playMode: "vod"`，底层走单路播放器的 `playVod()` 能力。
- 回放时间、进度拖动、状态变化都要按窗口 `uuid` 或当前 `index` 归档。
