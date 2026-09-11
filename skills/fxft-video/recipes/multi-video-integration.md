# 多路接入配方

1. 将设备映射为 `WebVideoChannel[]`，每路必须有稳定唯一 `id`。
2. 用 `{ columns: 2 }` 等 `WebVideoWallLayout` 控制布局，`mode` 缺省为 grid。
3. 全局 `autoplay` 可被 `channel.autoplay` 覆盖；用 `maxConcurrentStarts/startInterval` 错峰激活。
4. `reorder` 后用事件中的 `channels` 更新受控数组。
5. 普通点击单选，Ctrl 点击多选；用 `selectedId/selectedIds` v-model 同步。
6. 监听 `remove-channel` 后更新业务数组；API 删除同样只发请求。
7. 业务请求中用 Element Plus `v-loading` 覆盖整个视频墙；单通道请求错误写入 `channel.emptyText`，全局 `emptyText` 作为兜底，不弹消息。
8. 验证分屏切换不改顺序、不重建仍可见播放器，空位显示统一空态。
9. 开启缩放时按需设置 `dragMode`；放大后抓手模式平移画面，窗口模式才执行 Sortable 换位。
