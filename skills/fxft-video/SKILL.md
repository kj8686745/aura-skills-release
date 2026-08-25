---
name: fxft-video
description: 公司视频业务开发规范技能，指导 Agent 在 Vue 3 + Vite 项目中接入 @fxft/ui-plus，并使用 FxftVideoPlayer 与 FxftMultiVideoPlayer 完成单路监控、多路分屏、录像回放、点播、PTZ、全屏和拖拽换位。
compatibility: Claude Code；Vue 3；Vite；TypeScript；@fxft/ui-plus
metadata:
  version: "1.0.1"
  type: project-development-standard
  project: fxft-video
  stack: Vue 3 / Vite / TypeScript / @fxft/ui-plus / FxftVideoPlayer / FxftMultiVideoPlayer
---
# fxft-video 视频业务开发规范

你是公司视频业务开发规范执行器。后续任何涉及单路视频、多路视频、直播、录像、点播、PTZ、全屏、拖拽换位的视频需求，都必须优先使用 `@fxft/ui-plus` 提供的 `FxftVideoPlayer` 或 `FxftMultiVideoPlayer` 完成，不得绕过组件库重复封装底层 `JessibucaPro` / `JessibucaProMulti` 能力。

## 首次调用提示

当前会话首次命中本技能时，简要说明：它负责使用组件库的视频组件；需要项目路径、流地址/播放模式、单路或多路及脚本资源信息；先核验 `@fxft/ui-plus` 版本，使用当前公开 API 时要求 `>= 1.0.36`。示例为“接入四路监控，支持 PTZ 和拖拽换位”“实现单路点播时间轴”。同一会话后续不重复；用户询问“怎么用”“帮助”或“示例”时读取并输出 [使用说明](USAGE.md) 的相关部分。

## 重要：先读哪些文件

| 任务类型 | 必读文件 |
|---|---|
| 任意视频业务 | `references/project-profile.md`、`references/video-business-rules.md`、`checklists/pre-development.md` |
| 安装或接入组件库 | `references/ui-plus-installation.md`、`recipes/install-and-resolver.md` |
| 单路直播或点播 | `templates/fxft-video-basic-page.md`、`references/video-component-guide.md`、`recipes/single-video-integration.md` |
| 单路 PTZ 监控 | `templates/fxft-video-ptz-page.md`、`references/video-component-guide.md`、`recipes/single-video-integration.md` |
| 单路录像回放 | `templates/fxft-video-playback-page.md`、`recipes/playback-and-state-handling.md` |
| 多路分屏播放 | `templates/fxft-multi-video-basic-page.md`、`references/video-component-guide.md`、`recipes/multi-video-integration.md` |
| 多路拖拽换位 | `templates/fxft-multi-video-draggable-page.md`、`references/video-business-rules.md`、`recipes/multi-video-integration.md` |
| 多路录像或点播 | `templates/fxft-multi-video-playback-page.md`、`recipes/playback-and-state-handling.md` |
| 交付前验证 | `checklists/implementation.md`、`checklists/validation.md` |

## 技能目录结构

```text
fxft-video/
├── SKILL.md
├── README.md
├── USAGE.md
├── DESIGN.md
├── references/
├── templates/
├── checklists/
├── recipes/
└── scripts/
```

## 强制工作流

1. **识别视频需求**：凡是涉及监控直播、录像回放、点播文件、多路分屏、大屏轮巡、PTZ、全屏、拖拽换位的任务，都按本技能执行。
2. **先检查目标项目依赖和版本**：读取目标项目 `package.json` 与 lock 文件，确认是否存在并实际解析 `@fxft/ui-plus` 版本；当前单路/多路公开 Props、Events 与 Exposes 以 `>= 1.0.36` 为准。
3. **版本不足或未安装时必须授权**：不得静默安装或升级；先说明所需版本、会修改依赖与 lock 文件，用户明确授权后才使用项目现有包管理器通过公司私有 registry 安装或升级。
4. **复用包管理器**：根据 lock 文件或项目脚本判断使用 npm、pnpm 或 yarn，禁止混用包管理器。
5. **检查按需引入配置**：检查 `vite.config.ts` 是否已有 `unplugin-vue-components`、`unplugin-auto-import` 和 `FxftUiPlusResolver`。
6. **优先按需引入**：默认使用 `FxftUiPlusResolver` 按需引入组件和样式；只有目标项目已有全量注册约定时，才沿用全量注册。
7. **必须使用视频组件**：单路业务使用 `<FxftVideoPlayer>`，多路业务使用 `<FxftMultiVideoPlayer>`；不得自行封装底层播放器替代组件库能力。
8. **先判断单路或多路**：单路读取 `fxft-video-*` 模板，多路读取 `fxft-multi-video-*` 模板。
9. **再判断播放模式**：按直播 `live`、录像 `record`、点播 `vod` 匹配事件、状态和模板；点播优先走组件内部 `playVod` 能力。
10. **明确事件与公开方法**：只使用组件文档公开的 events 和 exposes；单路点播监听 `playVodTime`，多路不假定转发该事件；多路窗口状态使用 `getSelectedWindowUuid()`、`getWindowStates()` 或 `getWindowItem()`，不得调用未公开的 `getWindowUuidList()`。
11. **回放进度同步走组件能力**：自定义时间轴或业务进度条需要控制单路进度时，调用 `setPlayProgress(seconds)`；需要监听点播当前进度时，监听 `playVodTime`；录像回放当前时间监听 `playback-timestamp`。
12. **多路优先使用 uuid**：拖拽换位场景下 `index` 会变化，业务通道绑定必须优先使用稳定 `uuid`。
13. **直播流沿用组件默认优化**：`FxftVideoPlayer` 与 `FxftMultiVideoPlayer` 的 `live` 模式已默认开启 MSE 并放宽加载和心跳超时，业务侧不要绕过组件自行创建 Jessibuca 实例；特殊流确需调整时只通过组件 `options` / `videos[].options` 覆盖。
14. **容器显示后触发尺寸重算**：多路组件已在初始化、播放和切分屏后自动延迟 `resize()`；如果页面存在弹窗、标签页、折叠面板等隐藏到显示的容器，显示后优先调用组件公开的 `resize()`。
15. **交付前验证**：按 `checklists/validation.md` 检查依赖、Resolver、播放、回放、PTZ、全屏、拖拽、空态、错误态和控制台状态。

## 当前项目硬性约束

- 不得绕过组件库直接封装或调用 `JessibucaPro` / `JessibucaProMulti` 完成业务页面，除非用户明确要求并说明原因。
- 不在未取得用户授权的情况下安装 `@fxft/ui-plus`、`unplugin-vue-components`、`unplugin-auto-import` 或任何新依赖。
- 私有 registry 地址仅用于安装命令，不写入业务代码、组件代码或运行时配置。
- 生产环境建议业务侧自托管 `jessibuca-pro.js`、`jessibuca-pro-multi.js` 和 decoder 资源，不随意写死临时 CDN。
- 单路点播优先使用 `playMode="vod"`，不要把 MP4/HLS 点播当普通直播流处理。
- 直播 FLV 优先使用组件库默认 `live` 配置；不要为了处理卡顿在业务页绕过 `FxftVideoPlayer` / `FxftMultiVideoPlayer` 直接调用底层播放器。
- 多路拖拽换位时不得把 `index` 当作长期稳定业务标识，必须优先使用 `uuid`。
- 多路组件所在容器隐藏后再显示、切分屏或布局变更后，如发现画面尺寸异常，优先调用组件公开 `resize()`，不要直接改底层 `video` / `canvas` 样式。
- PTZ、全屏、拖拽、播放状态事件回调保持轻量，复杂逻辑拆到业务方法、API 模块或组合式函数。
- 空态、错误态、销毁重建、模式切换逻辑不能被业务层随意省略。
- 当前文档对应 `@fxft/ui-plus >= 1.0.36`；版本不足时不得使用新版接口，也不得自行补底层播放器调用。

## 与其它技能协作

- `/vueuse-functions`：涉及防抖节流、异步状态、浏览器 API、定时器时先调用。
- `/agent-browser`：涉及视频页面、交互、路由、样式和控制台验证时调用。
- `/planning-with-files-junmoxiao`：复杂视频业务、多页面视频功能或大屏轮巡开发时用于持久化规划。

## 交付格式

完成视频任务后按以下结构回复：

1. **完成内容**：列出新增/修改文件。
2. **使用的技能资料**：列出命中的 `templates/`、`references/`、`recipes/`、`checklists/`。
3. **依赖检查结果**：说明 `@fxft/ui-plus` 是否已存在，是否安装过依赖，若未安装说明是否获得授权。
4. **组件接入方式**：说明使用按需引入还是全量注册，`FxftUiPlusResolver` 是否配置。
5. **视频实现说明**：说明使用 `FxftVideoPlayer` 还是 `FxftMultiVideoPlayer`，以及直播、录像、点播、PTZ、全屏、拖拽换位能力。
6. **状态处理说明**：说明空态、错误态、销毁重建、多路 `uuid` 映射和回放事件处理方式。
7. **验证结果**：列出构建、类型检查、浏览器页面验证结果；未验证项必须说明原因。
8. **剩余风险**：列出依赖、私有 registry、视频脚本资源、decoder、真实流地址、浏览器兼容性等风险。
