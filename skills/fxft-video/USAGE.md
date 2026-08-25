# fxft-video 使用说明

## 适用、调用与版本前提

用于 Vue 3 + Vite 的单路/多路监控、直播、录像、点播、PTZ、全屏和拖拽换位。可根据需求自动触发，也可显式调用：`$fxft-video <需求>`；不用于要求绕过 `FxftVideoPlayer` / `FxftMultiVideoPlayer` 重写底层播放器的任务。

请提供项目路径、单路或多路、播放模式、流地址/录像地址、PTZ 协议及生产脚本资源路径。当前组件 Props、Events、Exposes 对应 `@fxft/ui-plus >= 1.0.36`；版本不足时先说明升级会改动依赖与 lock 文件，获得用户明确授权后才升级。

可复制提示词：

- `在当前项目接入四路监控视频，支持全屏、PTZ 和拖拽换位；先核验 @fxft/ui-plus 版本。`
- `开发单路点播页，使用 playVodTime 同步时间轴；版本不足 1.0.36 时先告诉我。`
- `新增多路录像回放，按 uuid 维护窗口状态，不依赖未公开 API。`

## 何时使用

当用户需求出现以下关键词或意图时，优先使用本技能：

- 视频、监控、摄像头、直播流
- 单路视频、多路视频、分屏、大屏轮巡
- 录像、录像回放、点播、MP4、HLS
- PTZ、云台、变倍、光圈、对焦、巡航、雨刷、除雾
- 全屏、单窗全屏、整体全屏
- 拖拽换位、窗口选中、窗口 uuid
- `@fxft/ui-plus`、`FxftVideoPlayer`、`FxftMultiVideoPlayer`、`FxftUiPlusResolver`

## 标准执行顺序

1. 读取 `SKILL.md`，确认任务类型和强制工作流。
2. 读取 `references/project-profile.md` 和 `references/video-business-rules.md`。
3. 检查目标项目 `package.json` 是否已安装 `@fxft/ui-plus`。
4. 检查目标项目 `vite.config.ts` 是否配置 `FxftUiPlusResolver`。
5. 判断单路或多路：
   - 单路基础：`templates/fxft-video-basic-page.md`
   - 单路 PTZ：`templates/fxft-video-ptz-page.md`
   - 单路回放：`templates/fxft-video-playback-page.md`
   - 多路基础：`templates/fxft-multi-video-basic-page.md`
   - 多路拖拽：`templates/fxft-multi-video-draggable-page.md`
   - 多路回放：`templates/fxft-multi-video-playback-page.md`
6. 按 `recipes/single-video-integration.md` 或 `recipes/multi-video-integration.md` 接入组件。
7. 涉及录像、点播、空态、错误态时读取 `recipes/playback-and-state-handling.md`。
8. 按 `checklists/validation.md` 完成验证并交付。

## 依赖安装授权话术

如果目标项目缺少 `@fxft/ui-plus`，先回复用户：

> 当前项目未检测到 `@fxft/ui-plus`，视频业务需要使用组件库提供的 `FxftVideoPlayer` / `FxftMultiVideoPlayer`。是否授权我使用项目现有包管理器，通过公司私有 registry 安装该依赖？

获得授权后，再按项目包管理器执行对应命令。

## 常见任务用法

### 开发单路监控直播页面

读取：

- `references/ui-plus-installation.md`
- `references/video-component-guide.md`
- `templates/fxft-video-basic-page.md`
- `recipes/single-video-integration.md`

重点验证：

- 使用 `<FxftVideoPlayer>`。
- `url` 有值时可播放，无值时显示空态。
- `@ready`、`@play`、`@error` 事件处理清晰。
- 生产环境资源路径有自托管说明。

### 接入 PTZ 云台控制

读取：

- `templates/fxft-video-ptz-page.md`
- `references/video-business-rules.md`

重点验证：

- `operateButtons.ptz` 已开启。
- 使用 `@ptz` 接收方向和扩展控制事件。
- PTZ 回调只做轻量派发，命令调用拆到业务方法或 API 层。

### 实现单路录像回放或点播

读取：

- `templates/fxft-video-playback-page.md`
- `recipes/playback-and-state-handling.md`

重点验证：

- `playMode` 使用 `record` 或 `vod`。
- 点播场景使用 `playMode="vod"`，由组件优先走 `playVod`；录像场景使用 `playMode="record"`，由组件走 `playback`。
- 监听 `playback-timestamp`、`playback-stats`、`playback-seek`。
- 需要同步自定义时间轴时监听 `playVodTime`，主动跳转时调用 `setPlayProgress(seconds)`。

### 开发多路分屏播放

读取：

- `templates/fxft-multi-video-basic-page.md`
- `recipes/multi-video-integration.md`

重点验证：

- 使用 `<FxftMultiVideoPlayer>`。
- `videos` 项按 `MultiVideoItem` 组织。
- 使用 `playWindow()`、`pauseWindow()`、`arrangeWindow()` 等公开方法。

### 多路视频拖拽换位

读取：

- `templates/fxft-multi-video-draggable-page.md`
- `references/video-business-rules.md`

重点验证：

- 开启 `draggable`。
- 监听 `drop` 同步业务顺序。
- 业务通道绑定使用 `uuid`，不要把变化后的 `index` 当作长期稳定标识。

## 不允许的做法

- 不检查依赖就直接写视频页面。
- 未经授权安装 `@fxft/ui-plus` 或其它依赖。
- 绕过 `FxftVideoPlayer` / `FxftMultiVideoPlayer` 自行封装底层播放器。
- 把公司私有 registry 写入业务代码。
- 多路拖拽场景长期依赖窗口 `index` 做业务通道绑定。
