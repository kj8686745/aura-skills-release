# 多路拖拽模板

```vue
<FxftWebMultiVideo
  :channels="channels"
  :layout="{ columns: 3, maxVisible: 6 }"
  :draggable="true"
  drag-mode="pan"
  @reorder="channels = $event.channels"
/>
```

`reorder` 返回完整稳定顺序 `{ ids, channels }`。业务以 `channel.id` 关联设备，不以槽位序号关联。分屏切换不触发 reorder，也不重建仍可见的视频节点。画面放大后可在抓手模式与窗口模式之间切换：抓手只平移画面，窗口模式才触发换位。
