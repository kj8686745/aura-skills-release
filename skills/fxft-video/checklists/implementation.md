# 实现检查清单

## 组件使用

- [ ] 单路页面使用 `FxftVideoPlayer` 或 `fxft-video-player`。
- [ ] 多路页面使用 `FxftMultiVideoPlayer` 或 `fxft-multi-video-player`。
- [ ] 没有绕过组件库直接封装 `JessibucaPro` / `JessibucaProMulti`。
- [ ] 通过 `ref` 调用组件公开 exposes。
- [ ] 没有使用未在组件文档中说明的内部私有字段。

## 依赖接入

- [ ] 已复用目标项目现有包管理器。
- [ ] 已复用或补齐 `FxftUiPlusResolver`。
- [ ] 没有覆盖已有 Vite 插件配置。
- [ ] 未将私有 registry 地址写入业务代码。

## 单路视频

- [ ] `url` 为空时有空态处理。
- [ ] `@error` 已处理播放或脚本加载错误。
- [ ] `playMode` 符合业务：`live` / `record` / `vod`。
- [ ] 点播文件使用 `playMode="vod"`。
- [ ] 需要 PTZ 时已开启 `operateButtons.ptz` 并监听 `@ptz`。
- [ ] 需要回放时已监听 `playback-timestamp`、`playback-stats`、`playback-seek`。
- [ ] 需要同步自定义时间轴时已监听 `playVodTime`，主动跳转时调用 `setPlayProgress(seconds)`。

## 多路视频

- [ ] `videos` 数据结构符合 `MultiVideoItem`。
- [ ] 多路窗口有稳定 `uuid` 或业务 `id`。
- [ ] 拖拽换位场景未把 `index` 当作长期稳定业务标识。
- [ ] 已监听 `selected`、`drop` 或 `status-change` 等必要事件。
- [ ] 单窗口错误不会影响其它窗口。
- [ ] 单窗全屏与整体全屏逻辑区分清楚。

## 业务逻辑

- [ ] 视频事件回调保持轻量。
- [ ] PTZ、拖拽同步、播放控制、错误上报等复杂逻辑拆到业务方法、API 模块或组合式函数。
- [ ] 空数据场景不会误触发播放请求。
- [ ] 切换流地址、播放模式或窗口布局时状态同步清晰。

## 代码风格

- [ ] Vue 页面优先使用 `<script setup>`。
- [ ] 注释和用户可见说明使用简体中文。
- [ ] 新增类型命名具备业务语义。
- [ ] 没有把 token、Cookie、密码写入代码。
- [ ] 生产资源路径通过配置或常量管理。
