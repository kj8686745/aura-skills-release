# 回放与状态处理配方

## 1. 播放模式

视频组件统一使用 `playMode` 区分播放类型：

- `live`：直播。
- `record`：录像回放。
- `vod`：点播文件。

点播模式下，组件内部优先调用 `playVod(url, { useLastFrameShow: true })`；暂停恢复时调用 `playVodResume()`。录像 `record` 模式初始播放调用 `playback(url, options)`，暂停恢复时调用 `playbackResume()`。

主动设置播放进度统一使用组件公开方法 `setPlayProgress(seconds)`：

- `vod` 模式调用 Jessibuca Pro 官方 `playVodSeek(time)`。
- `record` 模式调用 Jessibuca Pro 官方 `setPlaybackStartTime(timestamp)`。
- 业务侧不要绕过组件调用未文档化的底层私有字段，也不要使用 DOM `video.currentTime` 兜底。

## 2. 单路回放事件

```vue
<FxftVideoPlayer
  :url="recordUrl"
  play-mode="record"
  @playback-timestamp="onPlaybackTimestamp"
  @playback-stats="onPlaybackStats"
  @playback-seek="onPlaybackSeek"
  @play-vod-time="onPlaybackProgress"
/>
```

```typescript
const onPlaybackTimestamp = (payload: any) => {
  const value = payload?.value || {};
  console.log(value.hour, value.min, value.second);
};

const onPlaybackProgress = (payload: any) => {
  const value = payload?.value || {};
  console.log(value.currentTime, value.duration, value.bufferedTime, value.percent);
};

const seekTo = async (seconds: number) => {
  await videoRef.value?.setPlayProgress?.(seconds);
};
```

## 3. 多路回放事件

多路事件需要按窗口归档：

```typescript
const onPlaybackTimestamp = (payload: any) => {
  const key = payload.uuid || `index-${payload.index}`;
  updateWindowPlaybackTime(key, payload.value);
};
```

拖拽场景优先使用 `uuid`，避免 `index` 变化导致状态串窗。

## 4. 空态处理

- `url` 为空时，单路显示空态。
- 多路无视频时，对应窗口显示空态。
- 业务自定义空态时，可使用单路 `empty` slot；多路当前由组件内部统一渲染。
- 空态不是错误，不应触发错误提示。

## 5. 错误态处理

播放失败时：

- 显示错误提示。
- 派发 `error` 事件。
- 单路显示手动播放遮罩。
- 多路只影响对应窗口。

错误回调示例：

```typescript
const onError = (payload: any) => {
  const message = payload?.value?.message || "视频播放异常";
  console.error(message, payload);
};
```

## 6. 销毁与重建

- 单路 `url` 变为空时组件会销毁播放器并回到空态。
- 单路 `playMode` 变化时会销毁旧实例并重新初始化。
- 多路可使用 `destroyWindow(indexOrUuid?)` 销毁指定窗口。
- 页面卸载时组件会自动销毁；业务侧如额外保存实例，需要同步清理引用。

## 7. 手动播放与重试

错误后用户可能需要手动重新播放。业务侧可以：

```typescript
videoRef.value?.play?.();
multiRef.value?.playWindow?.("camera-001", retryUrl);
```

重试前应确认 URL、鉴权、网络和 decoder 资源是否可用。

## 8. 生产资源风险

若开发环境正常、生产环境失败，优先检查：

- `jessibuca-pro.js` 或 `jessibuca-pro-multi.js` 是否可访问。
- `decoder-pro-simd.js` 路径是否正确。
- 流地址协议是否被浏览器安全策略拦截。
- HTTPS 页面是否引用了不安全的 HTTP 资源。
