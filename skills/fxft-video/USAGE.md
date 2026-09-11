# 使用说明

可自动触发，也可显式调用：`$fxft-video <需求>`。

可复制提示词：

- `使用 FxftWebVideo 接入单路 HLS 直播，开启截图和 PTZ。`
- `使用 FxftWebVideo 实现录像回放，支持时间轴和倍速。`
- `使用 FxftWebMultiVideo 实现 16 分屏、拖拽、Ctrl 多选和通道删除。`
- `把现有视频页面迁移到 FxftWebVideo 和 FxftWebMultiVideo。`

执行前提供目标项目路径、协议、流地址、`live/playback/vod` 类型、单路或多路及所需控制。技能会先核验 `@fxft/ui-plus >= 1.1.2`，缺失或版本不足时先请求安装/升级授权。

常用资料：

- API：`references/video-component-guide.md`
- 安装：`references/ui-plus-installation.md`
- 单路模板：`templates/fxft-video-basic-page.md`
- 多路模板：`templates/fxft-multi-video-basic-page.md`
- 验证：`checklists/validation.md`
