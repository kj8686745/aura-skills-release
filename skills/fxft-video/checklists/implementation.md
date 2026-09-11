# 实现检查

- [ ] 单路使用 `FxftWebVideo`，多路使用 `FxftWebMultiVideo`。
- [ ] Source 使用判别联合，内容类型没有旧 `record/recording` 值。
- [ ] 没有直接创建或暴露底层播放引擎。
- [ ] 空态、错误态、重连耗尽和不可见释放已处理。
- [ ] PTZ stop 不做节流，业务收到 stop 后立即停止设备。
- [ ] 多路顺序只由增删和 reorder 修改，布局切换只改变容量。
- [ ] 删除事件由业务更新受控 channels。
- [ ] 自动播放遵循 `channel.autoplay ?? autoplay`。
- [ ] 动态 FLV/MPEG-TS 未知音频能力时允许不传 `hasAudio`；未传或 true 可自动音频降级，false 从开始忽略音频。
- [ ] 单路业务请求通过动态 `emptyText` 显示加载，多路请求通过整墙 `v-loading` 显示。
- [ ] 无 Source 或请求失败通过空态呈现；多路单通道错误使用 `channel.emptyText`，没有重复弹消息提示。
