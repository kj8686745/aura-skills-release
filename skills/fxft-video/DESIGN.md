# fxft-video 设计说明

## 设计目标

`fxft-video` 的目标是把公司视频组件的接入方式沉淀为 Claude Code 可执行的开发规范，覆盖单路视频、多路视频、直播、录像、点播、PTZ、全屏和拖拽换位等常见业务。

本技能不直接开发 `@fxft/ui-plus` 组件库本身，而是指导业务项目正确使用组件库中已有的 `FxftVideoPlayer` 和 `FxftMultiVideoPlayer`。

## 为什么参考 fmap-2d

`fmap-2d` 已经形成稳定的技能分层：

- `SKILL.md` 作为入口和强约束。
- `references/` 存放组件指南、安装规则、业务规则。
- `templates/` 存放可复制的页面模板。
- `recipes/` 存放按步骤执行的开发配方。
- `checklists/` 存放开发前、实现中、交付前检查项。
- `scripts/validate-skill.ps1` 校验技能结构和关键内容。

视频技能采用同样结构，便于维护、校验和后续扩展。

## 信息来源

视频组件规则来自：

- `docs/VIDEO-PLAYER.md`
- `docs/MULTI-VIDEO-PLAYER.md`

安装接入规则参考：

- `fmap-2d/references/ui-plus-installation.md`
- `fmap-2d/recipes/install-and-resolver.md`

## 内容分层

### 入口层

`SKILL.md` 只保留技能触发、强制工作流、硬性约束和交付格式，避免把完整 API 堆在入口文件中。

### 规则层

`references/video-component-guide.md` 负责沉淀组件 API，`references/video-business-rules.md` 负责沉淀业务约束，例如空态、错误态、销毁重建、多路 `uuid` 稳定映射。

### 模板层

模板按业务场景拆分，而不是按组件 API 全量堆叠：单路基础、单路 PTZ、单路回放、多路基础、多路拖拽、多路回放。

### 配方层

配方负责告诉 Claude Code 如何按步骤完成任务，包括安装接入、单路接入、多路接入、回放和状态处理。

### 清单层

清单用于防止遗漏依赖检查、Resolver 配置、生产资源路径、错误态、拖拽换位、回放事件和浏览器验证。

## 关键设计取舍

1. **优先组件库，不重复封装底层播放器**：业务侧应复用 `FxftVideoPlayer` / `FxftMultiVideoPlayer`，只有用户明确要求时才考虑底层能力。
2. **安装规则独立成文**：`@fxft/ui-plus` 安装、私有 registry 和 Resolver 合并是多个技能共享的基础能力，需要单独维护。
3. **多路拖拽单独强调**：拖拽后 `index` 会变化，`uuid` 才是稳定映射键，这是多路业务最容易出错的点。
4. **状态处理单独成配方**：视频播放存在空态、错误态、手动播放遮罩、模式切换销毁重建等行为，必须从模板中抽出来单独说明。
5. **生产资源路径显式提醒**：开发环境可用 CDN 兜底，生产环境建议自托管播放器脚本和 decoder 资源。
