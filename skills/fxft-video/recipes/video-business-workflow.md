# 视频业务开发流程配方

## 1. 识别需求

先判断需求属于哪个场景：

- 单路直播。
- 单路录像回放。
- 单路点播。
- 单路 PTZ 控制。
- 多路分屏播放。
- 多路拖拽换位。
- 多路录像或点播。
- 单窗全屏或整体全屏。

## 2. 依赖检查

必须检查：

- `@fxft/ui-plus` 是否安装。
- `FxftUiPlusResolver` 是否配置。
- 项目是否已有全量注册。

缺依赖时必须先授权再安装。

## 3. 模板匹配

按场景读取：

- 单路基础：`templates/fxft-video-basic-page.md`
- 单路 PTZ：`templates/fxft-video-ptz-page.md`
- 单路回放：`templates/fxft-video-playback-page.md`
- 多路基础：`templates/fxft-multi-video-basic-page.md`
- 多路拖拽：`templates/fxft-multi-video-draggable-page.md`
- 多路回放：`templates/fxft-multi-video-playback-page.md`

## 4. 组件接入

单路统一使用：

```vue
<FxftVideoPlayer ref="videoRef" :url="videoUrl" />
```

多路统一使用：

```vue
<FxftMultiVideoPlayer ref="multiRef" :split="4" :videos="videos" />
```

## 5. 播放模式确认

- 直播：`playMode="live"`。
- 录像：`playMode="record"`。
- 点播：`playMode="vod"`，组件内部优先调用 `playVod`。

## 6. 事件处理

根据业务挂载事件：

- `@ready`
- `@play`
- `@pause`
- `@error`
- `@ptz`
- `@playback-timestamp`
- `@playback-seek`
- `@play-vod-time`
- `@selected`
- `@drop`
- `@fullscreen`
- `@multi-fullscreen`
- `@status-change`

事件回调只做轻量处理，复杂逻辑拆到业务方法或 API 模块。

## 7. 播放进度控制

单路自定义时间轴或业务进度条需要跳转进度时，调用组件公开方法：

```typescript
await videoRef.value?.setPlayProgress?.(seconds);
```

需要同步当前播放进度时监听：

```vue
<FxftVideoPlayer @play-vod-time="onPlaybackProgress" />
```

不要在业务层绕过组件操作底层私有字段或 DOM。

## 8. 多路窗口管理

为每个窗口提供稳定业务标识：

```typescript
const videos = [
  { uuid: "camera-001", id: 1, name: "一路", url: "ws://example.com/live/ch01" },
];
```

拖拽换位后用 `uuid` 同步业务顺序，不要把 `index` 当作长期稳定标识。

## 9. 状态处理

必须确认：

- 无视频时有空态。
- 播放失败时有错误态。
- `playMode` 切换时允许组件销毁重建。
- 多路窗口错误不影响其它窗口。
- 生产资源路径有自托管方案。

## 10. 验证与交付

按 `checklists/validation.md` 执行，并在交付中说明：

- 依赖状态。
- Resolver 状态。
- 使用的组件和模板。
- 播放模式和事件处理。
- 多路 `uuid` 映射策略。
- 验证结果和未验证风险。
