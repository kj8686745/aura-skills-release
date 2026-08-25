# 项目画像

## 技能定位

`fxft-video` 是公司视频业务开发规范技能，面向需要在前端业务项目中播放、控制或管理单路/多路视频的需求。

## 适用技术栈

- Vue 3
- Vite
- TypeScript
- Claude Code
- `@fxft/ui-plus`
- `FxftVideoPlayer`
- `FxftMultiVideoPlayer`

## 核心依赖

视频业务必须优先使用基础组件库：

```text
@fxft/ui-plus
```

核心视频组件为：

```text
FxftVideoPlayer
FxftMultiVideoPlayer
```

## 目标项目检查项

在任何视频业务实现前，先检查目标项目：

1. `package.json` 是否已安装 `@fxft/ui-plus`。
2. 是否存在 lock 文件，用于判断包管理器：
   - `pnpm-lock.yaml` → pnpm
   - `yarn.lock` → yarn
   - `package-lock.json` → npm
3. `vite.config.ts` 是否配置 `FxftUiPlusResolver`。
4. 项目是否已有 `Components`、`AutoImport` 插件配置，避免覆盖已有配置。
5. 项目是否已有全量注册 `FxftUiPlus`，若有则沿用现有约定。
6. 视频脚本与 decoder 资源是否有生产可用路径。

## 默认实现策略

- 默认使用按需引入。
- 单路默认使用 `<FxftVideoPlayer>`。
- 多路默认使用 `<FxftMultiVideoPlayer>`。
- 默认通过组件公开 exposes 控制播放、暂停、销毁、分屏、全屏。
- 默认把 PTZ、拖拽、播放状态事件拆到轻量业务方法中处理。
- 多路拖拽业务默认使用稳定 `uuid` 做通道绑定。

## 不适用场景

以下场景不应直接套用本技能，除非用户明确确认：

- 用户明确要求直接开发或修改 `@fxft/ui-plus` 组件库源码。
- 用户明确要求绕过组件库使用底层播放器，并说明原因。
- 目标项目不是 Vue 3 + Vite 体系，且无法使用 `@fxft/ui-plus`。
- 需要处理视频服务端转码、流媒体网关、鉴权签名等后端能力。
