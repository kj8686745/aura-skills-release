# @fxft/ui-plus 安装与接入规则

## 依赖检查

在实现任何 2D 地图业务前，必须先读取目标项目 `package.json`，检查：

```json
{
  "dependencies": {
    "@fxft/ui-plus": "..."
  }
}
```

如果未安装，不得静默安装。必须先向用户说明：

- 当前项目缺少 `@fxft/ui-plus`。
- 2D 地图业务需要使用组件库提供的 `FxftMap`。
- 安装依赖会修改项目依赖文件。
- 是否授权使用公司私有 registry 安装。

点位索引、聚合图层显隐、单点显隐和图标更新能力要求 `@fxft/ui-plus >= 1.0.34`。使用 `setPointLayerVisible`、`setPointVisible`、`updatePointSymbol` 前必须检查实际安装版本；低于该版本时先说明升级会修改依赖与 lock 文件，并取得用户授权。

使用 `playBatchTracks` 系列批量轨迹控制、`fitLayer`、`flyToLayer`、`exportImage`、`geojson-upload` 或新版 GeoJSON 交互时，要求 `@fxft/ui-plus >= 1.0.36`。版本不足时不得生成这些调用；先说明将修改 `package.json` 与 lock 文件，只有获得用户明确授权后才用项目现有包管理器升级。

## 安装命令

根据目标项目已有包管理器选择一个命令，不要混用。

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

## 全量注册

如果目标项目已经采用全量注册组件库，可以在 `main.ts` 中沿用：

```typescript
import { createApp } from "vue";
import App from "./App.vue";
import "@fxft/ui-plus/dist/index.css";
import FxftUiPlus from "@fxft/ui-plus";

const app = createApp(App);
app.use(FxftUiPlus);
app.mount("#app");
```

## 按需引入（推荐）

默认推荐按需引入。需要目标项目具备：

```bash
npm install -D unplugin-vue-components unplugin-auto-import
```

如果目标项目使用 pnpm 或 yarn，应使用对应包管理器安装开发依赖。

### vite.config.ts 配置

```typescript
import { defineConfig } from "vite";
import Components from "unplugin-vue-components/vite";
import AutoImport from "unplugin-auto-import/vite";
import FxftUiPlusResolver from "@fxft/ui-plus/resolver";

export default defineConfig({
  plugins: [
    AutoImport({
      resolvers: [FxftUiPlusResolver()],
    }),
    Components({
      resolvers: [FxftUiPlusResolver()],
    }),
  ],
});
```

## 合并已有插件配置

真实项目中通常已经存在 `plugins` 配置。补齐 resolver 时必须遵守：

1. 不覆盖已有 Vite 插件。
2. 不删除已有 resolver。
3. 如果已经存在 `Components(...)`，只追加 `FxftUiPlusResolver()`。
4. 如果已经存在 `AutoImport(...)`，只追加 `FxftUiPlusResolver()`。
5. 如果已有全量注册约定，不强行改为按需引入。

## 私有 registry 使用边界

私有 registry 地址：

```text
https://repository.fxft.online/repository/npm-public/
```

该地址只用于安装命令，不写入业务代码、组件代码或运行时配置。
