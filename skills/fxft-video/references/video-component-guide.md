# 视频组件指南

## 单路组件：FxftVideoPlayer

`FxftVideoPlayer` 是基于 `JessibucaPro` 封装的单路视频播放组件，支持直播、录像、点播、手动播放遮罩、PTZ 控制、全屏、播放统计、回放时间事件、空态、错误态和视频名称展示。

### 适用场景

- 单路监控直播。
- 单路录像回放。
- 单路点播文件播放。
- 需要 PTZ 云台控制的监控画面。
- 需要统一空态、错误态和播放遮罩的视频容器。

### 常用 Props

| 属性名 | 说明 | 类型 | 默认值 |
| --- | --- | --- | --- |
| `name` | 视频名称，显示在左上角 | `string` | `''` |
| `url` | 播放地址；为空时显示空态 | `string` | `''` |
| `autoplay` | 是否自动播放 | `boolean` | `false` |
| `playMode` | 播放模式 | `'live' \| 'record' \| 'vod'` | `'live'` |
| `decoderPath` | 解码器路径 | `string` | `''` |
| `scriptUrl` | `jessibuca-pro.js` 地址 | `string` | CDN 兜底 |
| `controlAutoHide` | Jessibuca 控制栏是否自动隐藏 | `boolean` | `true` |
| `supportDblclickFullscreen` | 是否支持双击全屏 | `boolean` | `false` |
| `operateButtons` | 操作按钮配置 | `object` | `{}` |
| `isResize` | 是否监听尺寸变化 | `boolean` | `true` |
| `hasAudio` | 是否开启音频解码能力 | `boolean` | `false` |
| `options` | 透传给 `JessibucaPro` 的额外初始化配置 | `Record<string, any>` | `{}` |

### OperateButtons

| 字段 | 说明 |
| --- | --- |
| `fullscreen` | 全屏按钮 |
| `play` | 播放/暂停按钮 |
| `audio` | 声音按钮 |
| `record` | 录制按钮 |
| `zoom` | 变倍按钮 |
| `screenshot` | 截图按钮 |
| `ptz` | 云台控制 |
| `ptzClickType` | 云台点击方式，`click` 或 `mouseDownAndUp` |
| `ptzMoreArrowShow` | PTZ 更多方向按钮 |
| `ptzZoomShow` | PTZ 变倍控制 |
| `ptzApertureShow` | PTZ 光圈控制 |
| `ptzFocusShow` | PTZ 对焦控制 |
| `ptzCruiseShow` | PTZ 巡航控制 |
| `ptzFogShow` | PTZ 除雾控制 |
| `ptzWiperShow` | PTZ 雨刷控制 |

### 播放模式

- `live`：直播流，默认调用底层 `play(url, options)`。
- `record`：录像流，组件内部调用底层 `playback(url, options)`；暂停恢复时调用 `playbackResume()`。
- `vod`：点播流，优先调用底层 `playVod(url, { useLastFrameShow: true })`；如果当前实例不存在 `playVod`，兜底调用 `play()`。
- 需要主动设置播放进度时，通过组件公开方法 `setPlayProgress(seconds)`，不要在业务侧绕过组件直接操作底层私有字段或 DOM。

### 直播默认优化

- 单路 `live` 模式默认开启 `useMSE: true`，并将 `loadingTimeout` 调整为 `20`、`heartTimeout` 调整为 `10`，用于降低 FLV 直播软解卡顿和弱网络下过快重连的问题。
- 单路和多路共用组件库的 `live` 默认配置；业务页不要绕过组件库自行创建 `JessibucaPro`。
- 特殊流地址确需调整底层参数时，通过组件 `options` 覆盖，例如只针对当前页面调整 `useMSE` 或超时时间。

### Events

事件 payload 通常包含：

```typescript
{
  url: string;
  status: string;
  playMode: "live" | "record" | "vod";
  value?: any;
  raw?: any[];
}
```

| 事件名 | 说明 |
| --- | --- |
| `ready` | `JessibucaPro` 实例创建完成 |
| `load` | 视频加载完成或状态变化 |
| `play` | 开始播放 |
| `pause` | 暂停播放 |
| `error` | 播放或脚本加载错误 |
| `ptz` | 云台控制事件，payload 含 `type` 方向 |
| `stats` | 播放统计 |
| `playback-timestamp` | 录像播放时间戳 |
| `playback-stats` | 录像统计 |
| `playback-seek` | 录像进度拖动或组件主动设置进度 |
| `playVodTime` | 点播 VOD 当前播放时间，仅 `playMode="vod"` 有效，`value` 含 `currentTime` / `duration` / `bufferedTime` / `percent` |
| `fullscreen` | 全屏状态变化 |
| `playVodEnded` | 点播 VOD 播放结束，仅 `playMode="vod"` 有效 |
| `close` | 播放器关闭 |

### Exposes

| 方法 | 说明 |
| --- | --- |
| `play()` | 根据当前 `url`、`playMode` 与暂停状态自动播放或恢复：`live` 调用 `play()`，`vod` 调用 `playVod()`/`playVodResume()`，`record` 调用 `playback()`/`playbackResume()` |
| `pause(isClear?)` | 根据当前 `playMode` 暂停：`vod` 调用 `playVodPause()`，`record` 调用 `playbackPause(true)`，`live` 调用 `pause()` |
| `setPlayProgress(seconds)` | 设置播放进度；`vod` 调用 `playVodSeek(time)`，`record` 调用 `setPlaybackStartTime(timestamp)` |
| `destroy()` | 销毁播放器实例 |
| `getInstance()` | 获取内部 `JessibucaPro` 实例 |

### Slots

| 插槽名 | 说明 |
| --- | --- |
| `name` | 自定义视频名称区域 |
| `empty` | 自定义无视频空态 |
| `error` | 自定义错误提示 |

### 生命周期与状态

- 组件挂载后加载 `JessibucaPro` 脚本，脚本加载完成后初始化播放器。
- `autoplay=true` 且 `url` 有值后自动播放。
- `url` 变为空时会销毁播放器并回到空态。
- `playMode` 变化时，会销毁旧实例并重新初始化；若 `autoplay=true`，会自动重播。
- 播放失败时进入错误态，派发 `error` 事件，并显示手动播放遮罩。
- 组件会将常见底层英文错误转换为中文提示；销毁过程中的 `JbPro is destroyed` / `is destroyed` 不展示为错误态。
- 组件卸载时自动销毁播放器。

## 多路组件：FxftMultiVideoPlayer

`FxftMultiVideoPlayer` 是基于 `JessibucaProMulti` 的多路视频播放组件，支持分屏布局、窗口拖拽换位、直播/录像/点播播放、选中窗口操作、PTZ 控制与完整事件透传。

### 适用场景

- 监控大屏、多窗口轮巡。
- 多路直播流同时播放。
- 多路录像回放与点播。
- 需要拖拽换位、切分屏、单窗操作的业务场景。

### 常用 Props

| 属性名 | 说明 | 类型 | 默认值 |
| --- | --- | --- | --- |
| `split` | 分屏布局，支持 `1`/`2`/`3`/`4`/`'3-1'`/`'4-1'` | `number \| string` | `2` |
| `maxSplit` | 最大分屏数 | `number` | `4` |
| `videos` | 窗口播放列表，见 `MultiVideoItem` | `MultiVideoItem[]` | `[]` |
| `autoplay` | 是否自动播放 `videos` | `boolean` | `false` |
| `playMode` | 默认播放模式 | `'live' \| 'record' \| 'vod'` | `'live'` |
| `decoderPath` | 解码器路径 | `string` | `''` |
| `multiScriptUrl` | `jessibuca-pro-multi.js` 地址 | `string` | CDN 兜底 |
| `controlAutoHide` | 控制栏自动隐藏 | `boolean` | `true` |
| `supportDblclickFullscreen` | 双击全屏 | `boolean` | `false` |
| `supportDblclickContainerFullscreen` | 双击容器内全屏 | `boolean` | `false` |
| `draggable` | 支持窗口拖拽换位 | `boolean` | `false` |
| `showSelectedBorder` | 显示选中边框 | `boolean` | `true` |
| `operateButtons` | 操作按钮配置 | `object` | — |
| `options` | 透传给 `JessibucaProMulti` 的额外初始化配置 | `object` | `{}` |

### MultiVideoItem

| 字段 | 说明 |
| --- | --- |
| `url` | 播放地址 |
| `index` | 指定绑定的窗口下标 |
| `uuid` | 窗口 uuid，拖拽后更稳定 |
| `id` | 业务标识 |
| `name` | 视频名称 |
| `playMode` | 覆盖全局 playMode |
| `options` | 该窗口专属播放参数 |
| `autoplay` | 该窗口是否自动播放 |

拖拽注意：开启 `draggable` 后，窗口 `index` 会随拖拽变化，`uuid` 才是稳定映射键。建议用 `uuid` 做业务通道绑定，监听 `drop` 事件后同步更新。

### Events

单窗口事件 payload 通常包含：

```typescript
{
  index: number;
  uuid?: string;
  item?: MultiVideoItem;
  url?: string;
  playMode?: string;
  value?: any;
  raw?: any[];
}
```

| 事件名 | 说明 |
| --- | --- |
| `ready` | 多路实例创建完成 |
| `load` | 单窗口播放器 load |
| `play` | 单窗口播放 |
| `pause` | 单窗口暂停 |
| `error` | 单窗口错误 |
| `selected` | 窗口选中 |
| `dbl-selected` | 窗口双击选中 |
| `drop` | 拖拽换位完成 |
| `ptz` | PTZ 控制 |
| `stats` | 直播统计 |
| `playback-timestamp` | 录像当前播放时间 |
| `playback-stats` | 录像统计 |
| `playback-seek` | 录像进度条拖动 |
| `fullscreen` | 单窗口全屏事件 |
| `multi-fullscreen` | 多路整体全屏事件 |
| `status-change` | 组件内部窗口状态变化 |
| `close` | 单窗口关闭 |

### Exposes

| 方法 | 说明 |
| --- | --- |
| `playWindow(indexOrUuid?, url?, options?)` | 播放指定窗口；不传则播放当前选中窗口 |
| `pauseWindow(indexOrUuid?, isClear?)` | 暂停指定窗口 |
| `destroyWindow(indexOrUuid?)` | 销毁指定窗口内部 player |
| `destroy()` | 销毁整个多路实例 |
| `arrangeWindow(split)` | 切换分屏布局 |
| `selectWindow(index)` | 选中指定窗口 |
| `resize(index?)` | 触发尺寸重算 |
| `setFullscreenMulti(flag)` | 整体全屏/退出全屏 |
| `toggleSingleWindowContainerFullscreen(flag?, indexOrUuid?)` | 单窗口容器内全屏 |
| `getInstance()` | 获取内部 `JessibucaProMulti` 实例 |
| `getWindowItem(indexOrUuid?)` | 获取窗口 DOM/player 信息 |
| `getSelectedWindowIndex()` | 获取当前选中窗口下标 |
| `getSelectedWindowUuid()` | 获取当前选中窗口 uuid |
| `getWindowStates()` | 获取所有窗口状态数组 |

### 多路关键行为

- 支持 `split` 分屏布局：`1` / `2` / `3` / `4` / `3-1` / `4-1`。
- 支持单窗口和多窗口同时播放。
- 支持每个窗口单独配置 `playMode`、`autoplay`、`options`。
- 多路 `live` 模式同样默认开启 `useMSE: true`，并使用 `loadingTimeout: 20`、`heartTimeout: 10` 的直播配置。
- 开启 `draggable` 后支持窗口拖拽换位。
- `selected`、`drop`、`getWindowUuidList()`、`getWindowItem()` 统一按 visual order 工作。
- 拖拽后选中窗口会同步更新到新位置。
- 无视频和播放失败按窗口单独管理，不影响其它窗口。
- 点播模式下通过底层单路播放器的 `playVod()` 执行。
- 多路组件在初始化、单窗口初始化、窗口播放和切分屏后会延迟触发 `resize()`，用于避免底层 `video` / `canvas` 偶发按旧尺寸渲染。
- 如果多路组件所在容器由隐藏变为显示，业务侧可在显示后调用公开方法 `resize(index?)` 主动重算尺寸。
- 销毁过程中的 `JbPro is destroyed` / `is destroyed` 不作为窗口错误态展示。
