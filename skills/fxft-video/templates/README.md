# 视频模板索引

本目录提供 `FxftVideoPlayer` 与 `FxftMultiVideoPlayer` 的常见业务模板。使用前必须先检查目标项目是否安装 `@fxft/ui-plus`，并确认 `FxftUiPlusResolver` 或全量注册方式可用。

## 单路模板

| 模板 | 适用场景 |
| --- | --- |
| `fxft-video-basic-page.md` | 单路直播、单路点播基础页面 |
| `fxft-video-ptz-page.md` | 需要 PTZ 云台控制的单路监控页面 |
| `fxft-video-playback-page.md` | 单路录像回放或点播页面 |

## 多路模板

| 模板 | 适用场景 |
| --- | --- |
| `fxft-multi-video-basic-page.md` | 多路分屏播放基础页面 |
| `fxft-multi-video-draggable-page.md` | 支持拖拽换位的多路视频页面 |
| `fxft-multi-video-playback-page.md` | 多路录像回放或点播页面 |

## 使用顺序

1. 先判断单路还是多路。
2. 再判断直播、录像、点播、PTZ、拖拽、全屏等能力。
3. 复制最接近的模板到业务页面。
4. 按真实接口替换 `url`、`videos`、`decoderPath`、`scriptUrl` 或 `multiScriptUrl`。
5. 事件回调保持轻量，复杂逻辑拆到业务方法或 API 模块。
