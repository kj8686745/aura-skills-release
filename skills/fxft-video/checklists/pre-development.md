# 开发前检查清单

在开始任何视频业务开发前，逐项确认。

## 需求确认

- [ ] 已确认需求属于视频业务。
- [ ] 已识别业务场景：单路 / 多路。
- [ ] 已识别播放模式：直播 / 录像 / 点播。
- [ ] 已确认是否需要 PTZ 云台控制。
- [ ] 已确认是否需要全屏、单窗全屏或整体全屏。
- [ ] 已确认是否需要多路拖拽换位。
- [ ] 已确认视频容器所在页面或路由。
- [ ] 已确认真实流地址、录像地址或点播地址来源。

## 依赖检查

- [ ] 已读取目标项目 `package.json`。
- [ ] 已确认是否安装 `@fxft/ui-plus`。
- [ ] 如果未安装，已向用户说明并等待授权。
- [ ] 已确认目标项目包管理器，不混用 npm、pnpm、yarn。

## 接入检查

- [ ] 已检查 `vite.config.ts`。
- [ ] 已确认是否配置 `unplugin-vue-components`。
- [ ] 已确认是否配置 `unplugin-auto-import`。
- [ ] 已确认是否配置 `FxftUiPlusResolver`。
- [ ] 已确认目标项目是否已有全量注册 `FxftUiPlus`。

## 视频资源检查

- [ ] 已确认 decoder 路径。
- [ ] 已确认生产环境是否需要自托管 `jessibuca-pro.js`。
- [ ] 多路场景已确认是否需要自托管 `jessibuca-pro-multi.js`。
- [ ] 已确认资源路径不会写死为临时不可用地址。

## 资料读取

- [ ] 已读取 `references/project-profile.md`。
- [ ] 已读取 `references/video-business-rules.md`。
- [ ] 已读取命中的视频模板。
- [ ] 涉及安装时已读取 `references/ui-plus-installation.md` 和 `recipes/install-and-resolver.md`。
- [ ] 涉及录像、点播、空态、错误态时已读取 `recipes/playback-and-state-handling.md`。
