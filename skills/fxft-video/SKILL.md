---
name: fxft-video
description: 在 Vue 3 + Vite 项目中使用 @fxft/ui-plus 的 FxftWebVideo 与 FxftWebMultiVideo 实现直播、回放、点播、PTZ、分屏、拖拽、多选和通道管理。
metadata:
  version: "2.0.5"
  type: project-development-standard
  project: fxft-video
  stack: Vue 3 / Vite / TypeScript / @fxft/ui-plus / FxftWebVideo / FxftWebMultiVideo
---

# fxft-video

使用 `@fxft/ui-plus` 的新版 Web 视频组件：单路使用 `FxftWebVideo`，多路使用 `FxftWebMultiVideo`。只依据本技能记录的公开 API 开发，不套用其它播放器的 Props、Events、Exposes、脚本或 decoder 配置。

## 先读哪些资料

| 任务 | 必读 |
|---|---|
| 任意接入或迁移 | `references/project-profile.md`、`references/video-business-rules.md` |
| 查 Props、Events、Exposes、类型 | `references/video-component-guide.md` |
| 安装、Resolver、样式 | `references/ui-plus-installation.md` |
| 单路直播/点播 | `templates/fxft-video-basic-page.md` |
| 单路 PTZ | `templates/fxft-video-ptz-page.md` |
| 单路回放 | `templates/fxft-video-playback-page.md` |
| 多路分屏/拖拽/回放 | 对应 `templates/fxft-multi-video-*.md` |
| 交付前 | `checklists/validation.md` |

## 工作流

1. 读取目标项目 `package.json` 和 lock 文件，确认包管理器及实际 `@fxft/ui-plus` 版本。使用本文 API 要求 `>= 1.1.2`；安装或升级前必须获得用户授权。
2. 检查项目是全量注册还是 `FxftUiPlusResolver` 按需引入，沿用现有方式，不混用包管理器。
3. 用 `WebVideoSource` 建模播放源：`native`、`hls`、`flv`、`mpegts` 或 `webrtc`；内容类型只使用 `live`、`playback`、`vod`。
4. 单路通过 `features` 开启录像、截图、画面缩放和 PTZ；不要自行创建 hls.js、mpegts.js 或 RTCPeerConnection。
5. 多路以稳定 `channel.id` 为唯一身份，布局用 `WebVideoWallLayout`。`mode` 缺省为 `grid`；内置布局为 1/4/6/9/16 分屏。
6. 拖拽只通过 `reorder` 更新业务数组；布局切换不得改写通道顺序。普通点击单选，`Ctrl + 点击` 追加或取消多选。
7. 通道移除是受控请求：监听 `remove-channel` 后由业务更新 `channels`。组件实例的 `removeChannel(id)` 与 `removeSelectedChannels()` 也只发请求。
8. 按真实协议验证空态、错误态、重连、播放控制、全屏、PTZ、拖拽、响应式布局和控制台。

## 关键契约

- `emptyText` 默认“暂无视频源”；单路 `empty` 插槽优先于文本。
- 业务接口请求视频数据时，单路通过动态 `emptyText` 显示加载文案；多路在整个视频墙容器使用 Element Plus `v-loading`。请求结束后，多路单通道错误写入 `channel.emptyText`，全局 `emptyText` 只作统一兜底。请求失败或没有 Source 时通过空态文本呈现，不额外弹出 `ElMessage`、toast 或弹窗。
- `fullscreen` 默认开启；录像、截图、缩放、PTZ 由 `features` 显式开启。
- PTZ 仅在 `source.kind === 'live'` 且播放器可操作时可用。按下事件为 `{ command, direction: command, phase: 'start', speed }`，松开为 `{ command, direction: 'stop', phase: 'stop', speed }`。
- 多路 `autoplay` 默认 `true`；`channel.autoplay` 优先于全局值。
- FLV/MPEG-TS 的 `hasAudio` 是三态：未传或 `true` 都优先启用音频，并在音频 codec 不支持时自动降级为仅视频；`false` 表示从开始就忽略音频。动态接口无法预知音频能力时保持未传。
- 浏览器 MSE 的音视频 codec 能力不能通过浏览器扩展或系统 Codec Pack 补齐。FLV 音频为 G.711A/PCMA 时，优先由服务端转为 AAC-LC，或改走支持 PCMA 协商的 WebRTC/WHEP；除非用户明确要求并接受成本，不在业务页增加 WASM 音频解码链路。
- `maxConcurrentStarts` 默认 `2`，`startInterval` 默认 `180ms`，用于错峰激活多路播放器。
- 单屏显示稳定顺序的第一路；4/6/9/16 分屏按顺序截取，不足补空槽，超出不删除。
- 视频失败必须进入错误态；自动重连耗尽后不得永久停在“正在建立视频连接”。
- 媒体连接和缓冲使用 `buffer` 配置；首次无画面时显示 `loadingText`，已经渲染过画面时重连保留上一帧。重连、切源或销毁主动中断的 `play()` 不作为新的媒体错误。
- 开启 `features.zoom` 后，短按缩放单步调整，长按连续调整。多路放大后用 `dragMode: 'pan' | 'window'` 区分画面平移和窗口换位；两种拖动互斥，不依赖标题是否显示。
- 不暴露或依赖底层播放引擎实例。

## 边界

- 服务端转码、流媒体网关、WHEP 转换、设备 PTZ 协议和鉴权签名属于业务/服务端，不写进组件。
- HTTP-FLV/HLS 跨域、HTTPS 混合内容和 Canvas 截图跨域由资源服务配置解决。
- 未经授权不安装依赖，不把私有 registry、token 或临时流地址写进业务代码。

## 交付

说明使用的组件与协议、依赖/Resolver 状态、关键状态处理、验证结果和仍受真实流或服务端配置限制的风险。无需机械列出所有技能文件。
