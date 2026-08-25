# 多路视频接入配方

## 1. 适用范围

本配方适用于：

- 多路直播同时播放。
- 多路分屏监控。
- 多窗口轮巡或大屏展示。
- 多路拖拽换位。
- 多路录像回放或点播。

## 2. 基础结构

```vue
<FxftMultiVideoPlayer
  ref="multiRef"
  :split="4"
  :videos="videos"
  :autoplay="true"
  decoder-path="/jessibucaPro/decoder-pro-simd.js"
  @selected="onSelected"
  @error="onError"
/>
```

## 3. videos 数据

建议每个窗口提供稳定 `uuid`：

```typescript
const videos = [
  { uuid: "camera-001", id: 1, name: "一路", url: "ws://example.com/live/ch01" },
  { uuid: "camera-002", id: 2, name: "二路", url: "ws://example.com/live/ch02" },
];
```

字段说明：

- `url`：播放地址。
- `index`：指定窗口下标，不适合作为拖拽后的长期稳定业务键。
- `uuid`：窗口稳定标识，推荐用于业务通道绑定。
- `id`：业务标识。
- `name`：视频名称。
- `playMode`：覆盖全局播放模式。
- `options`：窗口专属播放参数。
- `autoplay`：窗口是否自动播放。

## 4. 分屏控制

```typescript
multiRef.value?.arrangeWindow?.(4);
multiRef.value?.arrangeWindow?.("4-1");
```

`split` 支持 `1`、`2`、`3`、`4`、`3-1`、`4-1`。

## 5. 窗口播放控制

```typescript
multiRef.value?.playWindow?.("camera-001", "ws://example.com/live/ch01");
multiRef.value?.pauseWindow?.("camera-001");
multiRef.value?.destroyWindow?.("camera-001");
```

不传 `indexOrUuid` 时，默认操作当前选中窗口。

## 6. 拖拽换位

开启：

```vue
<FxftMultiVideoPlayer :draggable="true" @drop="onDrop" />
```

处理：

```typescript
const onDrop = (payload: any) => {
  const value = payload?.value || {};
  console.log("拖拽换位", value.fromUuid, value.toUuid);
  syncBusinessOrder();
};
```

拖拽后 `selected`、`drop`、`getWindowItem()` 按 visual order 工作。业务绑定优先使用 `uuid`。

## 7. 全屏控制

```typescript
multiRef.value?.setFullscreenMulti?.(true);
multiRef.value?.toggleSingleWindowContainerFullscreen?.(true, "camera-001");
```

- `fullscreen`：单窗口全屏事件。
- `multi-fullscreen`：多路整体全屏事件。

## 8. 状态与错误

- 窗口空态和错误态按窗口独立管理。
- 某一窗口错误不应影响其它窗口。
- `status-change` 可用于同步窗口内部状态。
- 错误事件中优先读取 `uuid`，拖拽场景不要只依赖 `index`。
- 多路直播默认已开启 `useMSE: true`，并使用 `loadingTimeout: 20`、`heartTimeout: 10`；单路和多路直播保持同一套组件默认配置。
- 销毁过程中的 `JbPro is destroyed` / `is destroyed` 由组件内部过滤，不需要业务侧重复处理。

## 9. 尺寸重算

组件在初始化、单窗口初始化、窗口播放和切分屏后会自动延迟触发 `resize()`。如果多路组件放在弹窗、标签页、折叠面板等先隐藏后显示的区域，容器显示后建议再主动调用一次：

```typescript
await nextTick();
multiRef.value?.resize?.();
```

特殊窗口需要覆盖底层播放参数时，可通过窗口级 `options` 传入：

```typescript
const videos = [
  {
    uuid: "camera-001",
    name: "一路",
    url: "http://example.com/live/camera-001.flv",
    options: { useMSE: true, loadingTimeout: 20, heartTimeout: 10 },
  },
];
```
