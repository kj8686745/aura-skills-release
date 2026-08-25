# FxftVideoPlayer 单路录像/点播页面模板

适用于单路录像回放或点播文件播放。

```vue
<template>
  <div class="video-page">
    <FxftVideoPlayer
      ref="videoRef"
      name="录像回放"
      :url="recordUrl"
      :autoplay="true"
      play-mode="record"
      decoder-path="/jessibucaPro/decoder-pro-simd.js"
      @playback-timestamp="onPlaybackTimestamp"
      @playback-stats="onPlaybackStats"
      @playback-seek="onPlaybackSeek"
      @play-vod-time="onPlaybackProgress"
      @error="onError"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";

const videoRef = ref<any>(null);
const recordUrl = ref("http://example.com/record/file.flv");
const currentTimeText = ref("00:00:00");

const onPlaybackTimestamp = (payload: any) => {
  const value = payload?.value || {};
  const hour = String(value.hour ?? 0).padStart(2, "0");
  const min = String(value.min ?? 0).padStart(2, "0");
  const second = String(value.second ?? 0).padStart(2, "0");
  currentTimeText.value = `${hour}:${min}:${second}`;
};

const onPlaybackStats = (payload: any) => {
  console.log("录像统计", payload.value);
};

const onPlaybackSeek = (payload: any) => {
  console.log("录像进度拖动", payload.value);
};

const onPlaybackProgress = (payload: any) => {
  const value = payload?.value || {};
  console.log("播放进度", value.currentTime, value.duration, value.bufferedTime, value.percent);
};

const seekTo = async (seconds: number) => {
  await videoRef.value?.setPlayProgress?.(seconds);
};

const onError = (payload: any) => {
  console.error("录像播放异常", payload.value?.message);
};

const playVodFile = (url: string) => {
  recordUrl.value = url;
  // 点播文件建议在模板中把 play-mode 改为 vod。
  videoRef.value?.play?.();
};
</script>

<style scoped>
.video-page {
  width: 100%;
  height: 100%;
  min-height: 360px;
  background: #000;
}
</style>
```

## 使用要点

- 录像流使用 `playMode="record"`。
- MP4/HLS 点播建议使用 `playMode="vod"`，组件内部优先调用 `playVod`。
- 回放时间通过 `playback-timestamp` 监听。
- 进度拖动通过 `playback-seek` 监听。
- 点播播放进度通过 `playVodTime` 监听，录像回放时间通过 `playback-timestamp` 监听。
- 自定义时间轴主动跳转时调用组件公开方法 `setPlayProgress(seconds)`。
