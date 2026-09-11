# 安装与 Resolver 配方

1. 根据 lock 文件确定 npm、pnpm 或 yarn。
2. 读取实际安装版本；新版 API 要求 `@fxft/ui-plus >= 1.1.2`。
3. 缺失或版本不足时先获授权，再通过公司 registry 安装。
4. 已有全量注册则沿用；否则在现有 `Components` 与 `AutoImport` 中追加 `FxftUiPlusResolver()`。
5. 构建并确认视频组件样式随组件加载。不要新增 Jessibuca 脚本或 decoder。
