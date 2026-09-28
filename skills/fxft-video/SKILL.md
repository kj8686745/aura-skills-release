---
name: fxft-video
description: 在 Vue 3 + Vite 项目中使用 @fxft/ui-plus 的 FxftWebVideo 与 FxftWebMultiVideo 实现直播、回放、点播、PTZ、分屏、拖拽、多选和通道管理。
metadata:
  version: "2.0.6"
  type: project-development-standard
  project: fxft-video
  stack: Vue 3 / Vite / TypeScript / @fxft/ui-plus / FxftWebVideo / FxftWebMultiVideo
---

# fxft-video

使用 `@fxft/ui-plus >= 1.1.2`：单路 `FxftWebVideo`，多路 `FxftWebMultiVideo`。依据组件公开 API，不套用其它播放器的配置，不自行创建 hls.js、mpegts.js 或 RTCPeerConnection，不依赖底层引擎实例。

## 执行入口

1. 检查 `package.json`、lock 文件和实际版本，沿用包管理器及现有 Resolver/全量注册方式；安装升级须用户授权。
2. 按下表读取任务命中的资料和章节，不固定全读；同一会话未变化的资料不重复读取。
3. 播放源使用 `WebVideoSource`；多路以稳定 `channel.id` 标识通道。业务请求失败用组件空态展示，不叠加消息弹窗；详细状态、PTZ 与受控数组规则见业务规则。
4. 按真实协议验证本次涉及的空态、错误、重连和交互；没有真实流时如实说明验证范围。

## 按场景读取

| 场景 | 必读资料 |
| --- | --- |
| 首次接入或迁移 | [项目画像](references/project-profile.md) |
| Source、业务加载/错误、重连、PTZ、多路状态 | [业务规则](references/video-business-rules.md) 对应章节 |
| Props、Events、Exposes、默认值或类型 | [组件 API](references/video-component-guide.md) 对应单路/多路章节 |
| 安装、Resolver、样式 | [安装规则](references/ui-plus-installation.md) |
| 单路直播/点播 | [基础模板](templates/fxft-video-basic-page.md) |
| PTZ / 单路回放 | [PTZ 模板](templates/fxft-video-ptz-page.md) / [回放模板](templates/fxft-video-playback-page.md) |
| 多路分屏 / 拖拽 / 回放 | [分屏模板](templates/fxft-multi-video-basic-page.md) / [拖拽模板](templates/fxft-multi-video-draggable-page.md) / [回放模板](templates/fxft-multi-video-playback-page.md) |
| 交付前验证 | [验证清单](checklists/validation.md) 中本次适用项 |
| 用户询问用法 | [使用说明](USAGE.md) |

## 边界与交付

服务端转码、网关、WHEP 转换、设备 PTZ 协议和鉴权签名属于业务/服务端；跨域、混合内容和截图资源权限由资源服务解决。私有 registry、token、临时流地址不写进业务代码。

说明实际使用的组件与协议、依赖/Resolver、状态处理、验证结果和真实流或服务端限制，不机械列出全部技能文件。
