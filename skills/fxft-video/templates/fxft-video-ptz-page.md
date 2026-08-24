# FxftVideoPlayer 单路 PTZ 页面模板

适用于需要云台方向、变倍、光圈、对焦等控制的单路监控页面。

```vue
<template>
  <div class="video-page">
    <FxftVideoPlayer
      ref="videoRef"
      name="球机一号"
      :url="videoUrl"
      :autoplay="true"
      play-mode="live"
      decoder-path="/jessibucaPro/decoder-pro-simd.js"
      :operate-buttons="operateButtons"
      @ptz="onPtz"
      @error="onError"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";

const videoRef = ref<any>(null);
const videoUrl = ref("ws://example.com/live/ptz01");

const operateButtons = {
  play: true,
  fullscreen: true,
  screenshot: true,
  ptz: true,
  ptzClickType: "mouseDownAndUp",
  ptzMoreArrowShow: true,
  ptzZoomShow: true,
  ptzApertureShow: true,
  ptzFocusShow: true,
  ptzCruiseShow: true,
  ptzFogShow: true,
  ptzWiperShow: true,
};

const onPtz = (payload: any) => {
  const type = payload?.type;
  if (!type) return;
  sendPtzCommand(type, payload);
};

const sendPtzCommand = (type: string, payload: any) => {
  // 这里调用业务 API，不要在事件中堆叠复杂逻辑。
  console.log("发送 PTZ 指令", type, payload);
};

const onError = (payload: any) => {
  console.error("PTZ 视频播放异常", payload.value?.message);
};
</script>

<style scoped>
.video-page {
  width: 100%;
  height: 100%;
  min-height: 420px;
  background: #000;
}
</style>
```

## 使用要点

- PTZ 开关来自 `operateButtons.ptz`。
- `@ptz` 事件只做参数整理和业务方法调用。
- PTZ 面板会根据容器高度自动缩放，但页面仍需提供足够高度。
