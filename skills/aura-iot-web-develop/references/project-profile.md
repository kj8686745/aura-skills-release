# 当前项目画像：foundation-dev-web

## 项目定位

`foundation-dev-web` 是 Aura IOT 体系中的前端子应用开发项目，当前是轻量 `Vue 3 + Vite + TypeScript + Element Plus + Pinia + Vue Router + qiankun` 项目。

它不是完整 PIGX 模板项目，因此必须把知识库中的通用规范改造成当前项目可执行规则。

## 技术栈事实

| 类别 | 当前项目 |
|------|----------|
| 框架 | Vue 3 |
| 构建 | Vite 8 |
| 语言 | TypeScript 6 |
| UI | Element Plus 2.14 |
| 状态 | Pinia 3 |
| 路由 | Vue Router 5 |
| 微前端 | qiankun / vite-plugin-qiankun |
| 样式 | SCSS + TailwindCSS 4 + PostCSS 前缀隔离 |
| 请求 | `src/utils/request.ts` 封装 Axios |
| 自动导入 | `unplugin-auto-import` 自动导入 `vue`、`vue-router`、`pinia` |
| 组件按需 | `unplugin-vue-components` + ElementPlusResolver Sass |
| VueUse | 已安装 `@vueuse/core` |

## 当前项目关键文件

| 文件 | 约束 |
|------|------|
| `src/main.ts` | 保留 qiankun 生命周期、`createAppRouter`、Pinia、`.foundation-dev-web` 根类注入、`setupAppMessageContext(app)` |
| `src/App.vue` | 保留 `<el-config-provider namespace="aura">` |
| `vite.config.ts` | 保留 Element Plus Sass `$namespace: 'aura'`、qiankun base 逻辑、AutoImport/Components 配置 |
| `postcss.config.js` | 保留 `.foundation-dev-web` 业务样式前缀和 Element Plus 变量桥接 |
| `src/router/index.ts` | 当前路由入口，新增本地页面时在此处扩展 |
| `src/utils/request.ts` | API 层必须复用，不在页面直接使用 axios |
| `src/hooks/` | 当前已补齐项目公共 hooks：`table.ts`、`echarts.ts`、`message.ts`、`form.ts` |

## PIGX 知识库适配规则

| 知识库旧规则 | 当前项目适配 |
|--------------|--------------|
| `/@/` 别名 | 改为 `@/` |
| `src/router/route.ts`、`dynamicRoutes` | 当前使用 `src/router/index.ts` 的 routes 数组 |
| `src/theme-core` 外壳 | 当前没有完整 theme-core，页面不应假设存在该外壳 |
| `src/hooks/table` 等完整封装 | 已已补齐部分 hooks 到当前项目 |
| `v-auth` | 当前未确认存在，不得凭空使用；需先检查项目指令 |
| `$t` / i18n | 当前未接入完整 i18n，不得凭空生成 `$t()` |
| 全局组件注册 | 当前未完整注册 PIGX 全局组件，需要时按技能内置封装标准补齐并适配 |

## 必须保护的隔离能力

- Element Plus namespace：`aura`
- 业务根类：`.foundation-dev-web`
- Element Plus 主题变量桥接：`--aura-*` 回退引用 `--el-*`
- qiankun base/routerBase/basename 注入能力
- 服务式 MessageBox app context 传递能力
