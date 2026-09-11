# 单路接入配方

1. 选择协议并创建 `WebVideoSource`。
2. 使用 `FxftWebVideo`，设置明确容器尺寸。
3. 只开启需要的 `features`；`fullscreen` 默认开启。
4. 监听 `state-change`、`error`，按需监听 `metrics`、`time-update`、`ptz-command`。
5. 通过 `WebVideoExpose` 控制播放、定位、缓冲、录像、缩放、画面拖动模式和全屏，不操作内部 video。
6. 业务请求中用动态 `emptyText` 显示加载/请求错误，不弹消息；用错误 Source 验证媒体 error 与 reconnect。
