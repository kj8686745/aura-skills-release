# 项目画像

## 适用栈

- Vue 3、Vite、TypeScript
- `@fxft/ui-plus >= 1.1.2`
- 单路 `FxftWebVideo`
- 多路 `FxftWebMultiVideo`

## 实现前检查

1. 读取 `package.json` 和唯一 lock 文件，确认实际包管理器与组件库版本。
2. 检查 `FxftUiPlusResolver` 或全量注册，沿用项目现状。
3. 明确单路/多路、协议、`live/playback/vod`、自动播放、音频、PTZ、全屏、拖拽和删除需求。
4. 确认容器具有明确宽高，真实流可从当前页面访问。

## 不适用

- 服务端转码、流媒体网关或设备控制协议实现。
- 非 Vue 3/Vite 项目。
- 用户明确要求使用其它播放器或直接开发组件库底层引擎。
