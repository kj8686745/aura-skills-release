# 视频业务规则

## 组件选型

- 单路直播、单路录像、单路点播使用 `FxftVideoPlayer`。
- 多路分屏、多窗口播放、大屏轮巡、窗口拖拽换位使用 `FxftMultiVideoPlayer`。
- 不得绕过组件库重复封装底层播放器能力。
- 直播 FLV 卡顿、重连或尺寸异常优先从组件配置和公开方法处理，不在业务页直接 new `JessibucaPro` / `JessibucaProMulti`。

## 单路状态规则

- `url` 为空时，组件渲染空态。
- 默认空态使用统一无视频图标；业务可通过 `empty` slot 自定义。
- 播放失败时进入错误态，显示错误提示，并展示手动播放遮罩；组件内部会将 `manualPlay` 置为 `true`。
- 错误事件必须通过 `@error` 处理，至少记录或提示失败原因。
- 组件内部会将常见底层英文错误转换为中文提示；销毁过程中的 `JbPro is destroyed` / `is destroyed` 不作为业务错误提示。
- `playMode` 变化时组件会销毁旧实例并重新初始化。
- 组件卸载时自动销毁播放器，业务侧不要重复保存已销毁实例。

## 播放模式规则

- `live` 用于直播流。
- `live` 默认开启 `useMSE: true`，并使用 `loadingTimeout: 20`、`heartTimeout: 10`，单路和多路保持一致。
- `record` 用于录像流，组件内部调用 Jessibuca Pro 官方 `playback(url, options)`。
- `vod` 用于点播文件，组件内部优先调用 Jessibuca Pro 官方 `playVod(url, { useLastFrameShow: true })`。
- `play()` 是统一播放入口，会根据 `playMode` 和暂停状态自动分发到 `play()`、`playVod()`、`playVodResume()`、`playback()` 或 `playbackResume()`。
- MP4/HLS 点播建议使用 `playMode="vod"`。
- 单路主动设置播放进度统一调用组件公开方法 `setPlayProgress(seconds)`；`vod` 内部调用 Jessibuca Pro 官方 `playVodSeek(time)`，`record` 内部调用 `setPlaybackStartTime(timestamp)`。
- 单路点播当前播放时间监听 `playVodTime`；录像回放当前时间监听 `playback-timestamp`；不要在业务层绕过组件操作底层私有字段或 DOM。

## PTZ 规则

- PTZ 能力通过 `operateButtons.ptz` 开启。
- `@ptz` 事件只作为云台方向和扩展控制事件出口。
- PTZ 事件回调应保持轻量，只做参数整理和业务方法调用。
- 具体云台命令、接口请求、权限判断应放在业务方法、API 模块或组合式函数中。
- PTZ 面板会根据容器高度自动缩放，页面容器仍需保证可用高度。

## 多路窗口规则

- `split` 支持 `1`、`2`、`3`、`4`、`3-1`、`4-1`。
- 每个 `videos` 项可单独配置 `playMode`、`autoplay`、`options`。
- 单个窗口的空态和错误态独立管理，不应影响其它窗口。
- 选中、双击、关闭、播放、暂停、全屏均按窗口粒度处理。
- 单窗口全屏关注 `fullscreen` 事件，整体全屏关注 `multi-fullscreen` 事件。
- 多路组件在初始化、单窗口初始化、窗口播放和切分屏后会自动延迟触发 `resize()`，减少画面跑位和旧尺寸渲染。
- 弹窗、标签页、折叠面板等隐藏到显示场景，容器显示后应优先调用公开方法 `resize()`。

## 拖拽换位规则

开启 `draggable` 后，窗口支持拖拽换位，必须遵守：

1. `selected`、`drop`、`getWindowItem()` 等行为按 visual order 工作。
2. 拖拽后窗口 `index` 会随视觉顺序变化，不再适合作为长期稳定业务标识。
3. `uuid` 才是稳定映射键。
4. 业务通道、设备 id、接口参数建议绑定到 `uuid` 或业务 `id`。
5. 监听 `drop` 事件后，应同步业务侧窗口顺序或通道映射。

## 事件处理规则

- 播放统计、回放时间戳、拖拽、PTZ、全屏事件回调都应保持轻量。
- 复杂逻辑拆到业务方法、API 模块或组合式函数。
- 事件 payload 中的 `value` 和 `raw` 是原始数据，使用前应判空。
- 多路事件 payload 中的 `index` 只代表当前窗口位置；拖拽场景优先读取 `uuid`。

## 生产资源规则

- 开发环境可以使用组件默认 CDN 兜底。
- 生产环境建议自托管 `jessibuca-pro.js`、`jessibuca-pro-multi.js` 和 decoder 资源。
- 资源路径不要散落在多个页面中，优先通过配置或常量统一维护。
