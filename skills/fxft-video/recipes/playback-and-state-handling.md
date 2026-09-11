# 回放与状态处理

- `kind: 'playback'` 用于录像回放，`kind: 'vod'` 用于点播。
- 用 `time-update`/`channel-time-update` 获取 `{ currentTime, duration, buffered }`。
- 单路通过 `seek(seconds)` 和 `setPlaybackRate(rate)` 控制时间轴与倍速。
- 播放地址变化由组件重建引擎；业务不要保留底层引擎引用。
- 自动重连期间允许显示最后一帧；重试耗尽必须转 error。
- 用 `buffer` 调整目标缓冲、最大直播延迟和卡顿重连时间；需要监控时监听 `buffer-change`。
- 销毁或重连主动打断 `play()` 属于预期中断，业务不应据此再调用一次 `reload()`。
- 多路状态按 `channel.id` 保存，拖拽后不得串窗。
