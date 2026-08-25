# 单路视频接入配方

## 1. 适用范围

本配方适用于：

- 单路监控直播。
- 单路录像回放。
- 单路点播文件播放。
- 单路 PTZ 云台控制。

## 2. 基础结构

```vue
<FxftVideoPlayer
  ref="videoRef"
  :url="videoUrl"
  :autoplay="true"
  play-mode="live"
  decoder-path="/jessibucaPro/decoder-pro-simd.js"
  @ready="onReady"
  @play="onPlay"
  @error="onError"
/>
```

## 3. 必填或常用属性

- `url`：播放地址；为空时显示空态。
- `autoplay`：是否自动播放。
- `playMode`：`live` / `record` / `vod`。
- `decoderPath`：decoder 资源路径。
- `scriptUrl`：生产环境建议传自托管脚本路径。
- `operateButtons`：控制播放、全屏、截图、PTZ 等按钮。
- `hasAudio`：需要音频时明确开启。
- `options`：透传给底层播放器的额外配置。

## 4. 事件接入

至少处理：

```typescript
const onReady = (instance: unknown) => {
  console.log("播放器已创建", instance);
};

const onError = (payload: any) => {
  console.error("播放异常", payload.value?.message);
};
```

按业务增加：

- `@ptz`：云台控制。
- `@stats`：播放统计。
- `@playback-timestamp`：录像时间戳。
- `@play-vod-time`：点播播放进度。
- `@fullscreen`：全屏状态变化。

## 5. 公开方法

通过 `ref` 调用组件 exposes：

```typescript
videoRef.value?.play?.();
videoRef.value?.pause?.();
videoRef.value?.setPlayProgress?.(10);
videoRef.value?.destroy?.();
const instance = videoRef.value?.getInstance?.();
```

不要直接保存并长期操作已销毁的底层实例。自定义时间轴或业务进度条需要跳转单路点播进度时，优先调用 `setPlayProgress(seconds)`。

## 6. PTZ 接入

```typescript
const operateButtons = {
  ptz: true,
  ptzClickType: "mouseDownAndUp",
  ptzZoomShow: true,
  ptzFocusShow: true,
};

const onPtz = (payload: any) => {
  if (!payload?.type) return;
  sendPtzCommand(payload.type, payload);
};
```

PTZ 命令调用应放在业务方法或 API 模块中。

## 7. 状态注意事项

- `url` 为空时显示空态。
- 播放失败时显示错误态和手动播放遮罩。
- `playMode` 变化时会销毁旧实例并重建。
- 组件卸载时自动销毁。
- 直播 `live` 模式默认已开启 `useMSE: true`，并使用 `loadingTimeout: 20`、`heartTimeout: 10`；普通 FLV 直播不需要业务侧额外封装底层播放器。
- 销毁过程中的 `JbPro is destroyed` / `is destroyed` 由组件内部过滤，不需要在业务错误提示里单独处理。

特殊流需要覆盖底层参数时，通过 `options` 传入：

```vue
<FxftVideoPlayer
  :url="videoUrl"
  play-mode="live"
  :options="{ useMSE: true, loadingTimeout: 20, heartTimeout: 10 }"
/>
```
