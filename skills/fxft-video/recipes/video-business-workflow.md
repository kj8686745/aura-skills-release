# 视频业务工作流

1. 确定单路或多路，以及 `live/playback/vod`。
2. 根据协议构造 `WebVideoSource`，不要把 URL 与协议分散在多个状态里。
3. 单路设置 `features`；多路构造稳定 `channel.id`、`layout` 和受控选择状态。
4. 把 PTZ、错误上报、排序保存和删除请求拆成业务方法。
5. 验证真实流、空 Source、错误地址、重连耗尽、暂停/恢复、全屏和容器尺寸。
