# 安装与 Resolver 接入配方

## 1. 检查 package.json

读取目标项目 `package.json`，确认：

```json
{
  "dependencies": {
    "@fxft/ui-plus": "..."
  }
}
```

若不存在，必须先请求用户授权。

## 2. 判断包管理器

按优先级判断：

1. 存在 `pnpm-lock.yaml`：使用 pnpm。
2. 存在 `yarn.lock`：使用 yarn。
3. 存在 `package-lock.json`：使用 npm。
4. 都不存在时，询问用户或沿用项目 README / 脚本约定。

## 3. 安装基础组件库

### npm

```bash
npm install @fxft/ui-plus -S --registry=https://repository.fxft.online/repository/npm-public/
```

### pnpm

```bash
pnpm install @fxft/ui-plus -S --registry=https://repository.fxft.online/repository/npm-public/
```

### yarn

```bash
yarn add @fxft/ui-plus -S --registry=https://repository.fxft.online/repository/npm-public/
```

## 4. 安装按需引入插件

如果目标项目尚未安装：

```bash
npm install -D unplugin-vue-components unplugin-auto-import
```

使用 pnpm 或 yarn 的项目要换成对应命令。

## 5. 补齐 vite.config.ts

先检查目标项目是否已有以下导入：

```typescript
import Components from "unplugin-vue-components/vite";
import AutoImport from "unplugin-auto-import/vite";
import FxftUiPlusResolver from "@fxft/ui-plus/resolver";
```

再检查 plugins 中是否已有：

```typescript
Components({
  resolvers: [FxftUiPlusResolver()],
})

AutoImport({
  resolvers: [FxftUiPlusResolver()],
})
```

## 6. 合并规则

如果已有 `Components`：

```typescript
Components({
  resolvers: [
    ExistingResolver(),
    FxftUiPlusResolver(),
  ],
})
```

如果已有 `AutoImport`：

```typescript
AutoImport({
  resolvers: [
    ExistingResolver(),
    FxftUiPlusResolver(),
  ],
})
```

不要把已有 resolver 删除或替换。

## 7. 全量注册兜底

如果项目已有全量注册规范，沿用：

```typescript
import "@fxft/ui-plus/dist/index.css";
import FxftUiPlus from "@fxft/ui-plus";

app.use(FxftUiPlus);
```

## 8. 视频资源配置

开发环境可使用组件默认脚本 CDN 兜底。生产环境建议自托管：

- `jessibuca-pro.js`
- `jessibuca-pro-multi.js`
- `decoder-pro-simd.js`

在页面中通过 `script-url`、`multi-script-url`、`decoder-path` 或业务配置传入，不要把临时地址散落到多个页面。

## 9. 验证

- 确认 `package.json` 依赖已更新。
- 确认 lock 文件符合项目包管理器。
- 确认 `vite.config.ts` 没有破坏已有插件。
- 构建或启动项目验证 `FxftVideoPlayer` / `FxftMultiVideoPlayer` 能被解析。
