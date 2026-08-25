# fxft-video 技能包

`fxft-video` 是公司视频业务开发规范技能，用于指导Agent 在 Vue 3 + Vite + TypeScript 项目中接入 `@fxft/ui-plus`，并统一使用 `FxftVideoPlayer` 与 `FxftMultiVideoPlayer` 实现视频业务。

当前版本：`1.0.1`。

## 适用场景

- 开发单路监控直播页面。
- 开发单路录像回放或点播页面。
- 接入 PTZ 云台控制。
- 开发多路视频分屏、大屏轮巡或多窗口播放页面。
- 实现多路窗口选中、拖拽换位、窗口级播放控制。
- 实现单窗全屏、多路整体全屏。
- 检查或补齐 `@fxft/ui-plus` 与 `FxftUiPlusResolver` 配置。

## 核心原则

1. 后续视频业务必须优先检查目标项目是否安装 `@fxft/ui-plus`。
2. 未安装依赖或当前功能要求更高版本时，不得静默安装或升级，必须先获取用户授权；本文档的视频 API 要求 `@fxft/ui-plus >= 1.0.36`。
3. 单路业务使用 `FxftVideoPlayer`，多路业务使用 `FxftMultiVideoPlayer`。
4. 不得绕过组件库重复封装底层播放器能力。
5. 多路拖拽换位场景下，业务绑定优先使用稳定 `uuid`，不要长期依赖会变化的 `index`。
6. 生产环境建议自托管播放器脚本和 decoder 资源。

## 技能结构

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

## 快速入口

- 技能入口：`SKILL.md`
- 依赖安装：`references/ui-plus-installation.md`
- 视频组件指南：`references/video-component-guide.md`
- 业务规则：`references/video-business-rules.md`
- 模板索引：`templates/README.md`
- 验证脚本：`scripts/validate-skill.ps1`
- 使用说明：[USAGE.md](USAGE.md)

## 示例需求

可以这样触发本技能：

- “开发单路监控直播页面”
- “接入摄像头 PTZ 控制”
- “实现录像回放页面”
- “做一个 4 分屏视频监控页”
- “多路视频支持拖拽换位”
- “检查项目是否已接入 @fxft/ui-plus 的视频组件”

## 验证

在 `fxft-video` 目录下执行：

```powershell
.\scripts\validate-skill.ps1
```

脚本会检查必要文件、关键字符串和技能入口结构。
