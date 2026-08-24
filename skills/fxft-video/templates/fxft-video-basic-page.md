# FxftVideoPlayer 单路基础页面模板

适用于单路直播或点播基础页面。

```vue
<template>
  <div class="video-page">
    <FxftVideoPlayer
      ref="videoRef"
      name="监控一号"
      :url="videoUrl"
      :autoplay="true"
      play-mode="live"
      decoder-path="/jessibucaPro/decoder-pro-simd.js"
      @ready="onReady"
      @play="onPlay"
      @pause="onPause"
      @error="onError"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";

const videoRef = ref<any>(null);
const videoUrl = ref("ws://example.com/live/ch01");

const onReady = (instance: unknown) => {
  console.log("播放器已创建", instance);
};

const onPlay = (payload: any) => {
  console.log("开始播放", payload.url);
};

const onPause = (payload: any) => {
  console.log("暂停播放", payload.url);
};

const onError = (payload: any) => {
  console.error("视频播放异常", payload.value?.message);
};

const play = () => {
  videoRef.value?.play?.();
};

const pause = () => {
  videoRef.value?.pause?.();
};

const destroy = () => {
  videoRef.value?.destroy?.();
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

- 容器必须有明确宽高，否则播放器无法正常展示。
- `url` 为空时组件会显示空态。
- `autoplay=true` 且 `url` 有值时会自动播放。
- 生产环境建议自托管 `jessibuca-pro.js` 和 decoder 资源。
