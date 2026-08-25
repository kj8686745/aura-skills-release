# 项目画像

## 技能定位

`fmap-2d` 是公司 2D 地图业务开发规范技能，面向需要在前端业务项目中展示或操作二维地图的需求。

## 适用技术栈

- Vue 3
- Vite
- TypeScript
- Agent
- `@fxft/ui-plus`
- `FxftMap`

## 核心依赖

地图业务必须优先使用基础组件库：

```text
@fxft/ui-plus
```

核心地图组件为：

```text
FxftMap
```

## 目标项目检查项

在任何 2D 地图业务实现前，先检查目标项目：

1. `package.json` 是否已安装 `@fxft/ui-plus`。
2. 是否存在 lock 文件，用于判断包管理器：
   - `pnpm-lock.yaml` → pnpm
   - `yarn.lock` → yarn
   - `package-lock.json` → npm
3. `vite.config.ts` 是否配置 `FxftUiPlusResolver`。
4. 项目是否已有 `Components`、`AutoImport` 插件配置，避免覆盖已有配置。
5. 项目是否已有全量注册 `FxftUiPlus`，若有则沿用现有约定。

## 默认实现策略

- 默认使用按需引入。
- 默认使用 `<FxftMap>` 或 `<fxft-map>`。
- 默认通过 `ref` 调用 `FxftMap` 的公开 Exposes。
- 默认把业务数据先转换为地图组件需要的标准字段。
- 默认把图层命名为具备业务语义的名称。

## 不适用场景

以下场景不应直接套用本技能，除非用户明确确认：

- 用户明确要求使用第三方地图 SDK，并说明原因。
- 需要开发 `FxftMap` 组件库本身。
- 需要修改地图 SDK 底层能力。
- 目标项目不是 Vue 3 + Vite 体系，且无法使用 `@fxft/ui-plus`。
