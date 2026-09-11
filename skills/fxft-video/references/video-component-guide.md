# 新版 Web 视频组件 API

依据 `@fxft/ui-plus@1.1.2`。

## WebVideoSource

```ts
type WebVideoContentKind = 'live' | 'playback' | 'vod'

type WebVideoSource =
  | { protocol: 'native'; url?: string; file?: File; kind?: WebVideoContentKind; mimeType?: string }
  | { protocol: 'hls'; url: string; kind?: WebVideoContentKind; request?: RequestOptions; lowLatency?: boolean }
  | { protocol: 'flv' | 'mpegts'; url: string; kind?: WebVideoContentKind; transport?: 'http' | 'websocket'; hasAudio?: boolean; hasVideo?: boolean; lowLatency?: boolean }
  | { protocol: 'webrtc'; endpoint: string; signaling: 'whep'; kind?: 'live'; request?: RequestOptions; rtcConfiguration?: RTCConfiguration }
```

FLV/MPEG-TS 的 `hasAudio`：未传表示自动模式；未传或显式 `true` 明确命中不受支持的音频 codec 时，组件只重建一次并关闭音频；显式 `false` 从开始就忽略音频。视频 codec 不支持时始终报错。流无音频、显式关闭音频或自动降级后，音量按钮和滑杆必须隐藏。

### 浏览器编码边界

- 浏览器扩展、系统 Codec Pack 或桌面播放器能否播放，不能改变 `MediaSource.isTypeSupported()` 的结果。
- mpegts.js 的 FLV/MSE 音频通常应使用 AAC/MP3；G.711A/PCMA 不可直接作为 MSE 音频轨播放。
- 需要保留 G.711A 声音时，首选服务端转 AAC-LC；若服务端支持标准 WHEP，也可使用 WebRTC 协商 PCMA。
- 前端 WASM 解码 G.711A 还需要 FLV 拆包、Web Audio 输出、音视频同步和性能治理，不作为默认业务方案。

## FxftWebVideo

主要 Props：

| Prop | 默认值 | 说明 |
|---|---:|---|
| `source` | `null` | 结构化播放源 |
| `title` | `''` | 标题 |
| `emptyText` | `'暂无视频源'` | 默认空态文本，`empty` 插槽优先 |
| `loadingText` | `'正在加载中'` | 首次尚无上一帧时的媒体加载文案 |
| `autoplay` / `muted` / `volume` | `true` / `true` / `1` | 自动播放与音频初值 |
| `fit` | `'contain'` | `contain/cover/fill` |
| `active` | `true` | false 时释放引擎 |
| `features` | `{}` | `play/stop/audio/fullscreen/zoom/record/snapshot/ptz/metrics` |
| `reconnect` | 3 次 | `{ enabled, retryCount, delay }` |
| `buffer` | 目标 1 秒 | `{ enabled, targetDuration, maxLatency, stallTimeout }` |
| `dragMode` | `'pan'` | 放大后的默认拖动模式；窗口模式由多路组件启用 |
| `suspendWhenHidden` | `true` | 不可见时释放 |
| `metricsInterval` | `2000` | 指标周期 ms |
| `controlsAutoHide` | `true` | 控制栏自动隐藏 |
| `doubleClickFullscreen` | `true` | 双击全屏 |
| `ptzSpeed` | `5` | PTZ 速度 |

Events：`update:muted`、`update:volume`、`update:dragMode`、`state-change`、`error`、`metrics`、`ptz-command`、`snapshot`、`recording-start`、`recording-stop`、`fullscreen-change`、`time-update`、`buffer-change`、`drag-mode-change`、`reconnecting`、`stop`。

Expose：`play()`、`pause()`、`seek(seconds)`、`setPlaybackRate(rate)`、`setBuffer(policy)`、`reload()`、`stop()`、`capture()`、`startRecording()`、`stopRecording()`、`zoomIn()`、`zoomOut()`、`resetZoom()`、`setDragMode(mode)`、`enterFullscreen()`、`exitFullscreen()`。

`emptyText` 用于 Source 尚未取得、业务请求失败或无视频源等业务空态。媒体已经开始连接后的 loading/error 由组件状态机显示。

`loadingText` 只在媒体首次连接且尚无上一帧时居中显示；已经播放过的画面在缓冲或重连时保留上一帧。`buffer-change` 返回 `{ buffered, target, liveLatency }`，时间单位均为秒。放大/缩小按钮短按单步、长按连续，缩回 `1×` 自动回中。

`WebVideoPtzEvent`：

```ts
interface WebVideoPtzEvent {
  command: WebVideoPtzCommand
  direction: WebVideoPtzCommand | 'stop'
  phase: 'start' | 'stop'
  speed: number
}
```

## FxftWebMultiVideo

```ts
interface WebVideoChannel {
  id: string
  title: string
  source?: WebVideoSource | null
  emptyText?: string
  loadingText?: string
  poster?: string
  fit?: 'contain' | 'cover' | 'fill'
  autoplay?: boolean
  buffer?: WebVideoBufferPolicy
  dragMode?: 'pan' | 'window'
  enabled?: boolean
  metadata?: Record<string, unknown>
}

type WebVideoWallLayout =
  | { mode?: 'grid'; columns: 1 | 2 | 3 | 4 | 5 | 6; maxVisible?: number }
  | { mode: 'focus'; focusId?: string; thumbnails?: 'right' | 'bottom'; thumbnailCount?: number }
```

主要 Props：

| Prop | 默认值 | 说明 |
|---|---:|---|
| `channels` | `[]` | 受控通道数组 |
| `layout` | `{ columns: 2 }` | mode 缺省为 grid |
| `selectedId` / `selectedIds` | `''` / `[]` | 主通道与 Ctrl 多选，支持 v-model |
| `emptyText` | `'暂无视频源'` | 通道和补位槽的全局空态兜底；低于 `channel.emptyText` |
| `loadingText` | `'正在加载中'` | 媒体加载文案；低于 `channel.loadingText` |
| `autoplay` | `true` | 全局值，低于 `channel.autoplay` |
| `draggable` | `true` | SortableJS 插入排序 |
| `features` | `{}` | 单路 features 加 `wallFullscreen/focusMode/removeChannel` |
| `maxConcurrentStarts` | `2` | 每批最多激活数 |
| `startInterval` | `180` | 批次间隔 ms |
| `suspendWhenHidden` | `true` | 不可见时释放 |
| `metricsInterval` | `3000` | 指标周期 ms |
| `buffer` | 目标 1 秒 | 全局缓冲策略；低于 `channel.buffer` |
| `dragMode` | `'pan'` | 放大后的默认拖动模式；低于 `channel.dragMode` |

Events：`update:selectedId`、`update:selectedIds`、`selected-change`、`selection-change`、`reorder`、`layout-change`、`channel-state-change`、`channel-error`、`channel-metrics`、`channel-time-update`、`channel-drag-mode-change`、`ptz-command`、`remove-channel`、`fullscreen-change`。

Expose：`play(channelId?)`、`pause(channelId?)`、`reload(channelId?)`、`removeChannel(channelId)`、`removeSelectedChannels()`、`focus(channelId)`、`enterFullscreen()`、`exitFullscreen()`。

多路业务接口请求期间在组件外层容器使用 Element Plus `v-loading`，不要把请求 loading 复制到各通道。请求结束后，单路失败设置对应 `channel.emptyText`；组件 `emptyText` 统一控制未设置通道文案和补位槽。优先级为 `channel.emptyText || emptyText`。

开启 `features.zoom` 后，拖动模式按钮固定占位以避免缩放按钮位移；`1×` 时禁用。放大后 `pan` 平移画面，`window` 执行窗口换位，两种行为互斥且不依赖标题是否显示。

移除事件：

```ts
interface WebVideoChannelRemoveEvent {
  ids: string[]
  channels: WebVideoChannel[]
  trigger: 'button' | 'keyboard' | 'api'
}
```
