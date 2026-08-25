# PIGX 前端开发总览

## 适用场景

本文档用于梳理当前 PIGX 前端项目的工程总览。

适用于以下场景：

- 在原型转码前快速理解 PIGX 项目的工程入口和运行机制
- 为模型生成页面代码提供统一的工程背景
- 为后续页面模式文档补充工程级上下文

本文档不是某一个页面模式规范，而是工程级认知入口。

---

## 项目定位

该项目是一个基于 `Vue 3 + Vite + TypeScript + Element Plus + Pinia + Vue Router` 的后台前端项目，并且不是一个完全独立的纯本地单体前端，而是与 `aura-core` 深度耦合的业务壳项目。

这个项目的重要特点有三点：

- 页面代码主要写在本地 `src/views`
- 布局、主题、部分 API、部分能力来自 `aura-core`（位于 `src/theme-core`）
- 路由不是纯本地静态模式，而是"本地补充路由 + 后端菜单动态路由 + 模块联邦远程路由加载"混合模式

---

## 技术栈

| 分类 | 技术 |
|------|------|
| 框架层 | `Vue 3.5`、`TypeScript`、`Vite 6` |
| UI 层 | `Element Plus` |
| 状态管理 | `Pinia` + `pinia-plugin-persist` |
| 路由 | `Vue Router 4` |
| 国际化 | `vue-i18n` |
| 请求层 | `axios`（统一封装在 `src/utils/request.ts`） |
| 样式层 | `SCSS`、`TailwindCSS` |
| 图表 | `ECharts`、`D3` |
| 编辑器 | `TinyMCE`、`WangEditor`、`CodeMirror` |
| 工程增强 | `unplugin-auto-import`、`vite-plugin-vue-setup-extend` |
| 模块联邦 | `@originjs/vite-plugin-federation` |
| 布局插件 | `splitpanes` |
| Mock | `vite-plugin-mock` |

### 技术栈判断结论

- 页面框架必须遵循 `Vue 3 + script setup + TypeScript`
- UI 组件必须使用 `Element Plus`
- 常见后台页组织方式依赖全局组件、Pinia、路由 meta 和请求封装
- 布局与主题不是页面自己控制，而是受 `aura-core/theme-core` 接管
- `ref`/`reactive`/`computed`/`onMounted` 等 Vue API 通过 `unplugin-auto-import` 自动导入，**无需手动 import**

---

## 启动与构建方式

| 命令 | 说明 |
|------|------|
| `pnpm dev` | 本地开发（实际执行 `vite --force`） |
| `pnpm build` | 生产构建（额外设置 `NODE_OPTIONS=--max-old-space-size=8192`） |
| `pnpm build:docker` | Docker 构建 |
| `pnpm lint:eslint` | ESLint 修复 |
| `pnpm prettier` | 代码格式化 |
| `pnpm preview` | 构建预览 |

---

## 目录结构

```
src/
├── main.ts              # 应用启动入口
├── App.vue              # 应用根组件
├── router/              # 路由定义、后端路由初始化、模块联邦路由注册
│   ├── route.ts         # 路由表定义（staticRoutes / dynamicRoutes / baseRoutes）
│   ├── index.ts         # 路由实例
│   └── backEnd.ts       # 后端菜单路由处理
├── views/               # 页面级业务视图，原型转码主要落点
│   ├── admin/           # 系统管理类页面
│   ├── biz/             # 业务类页面
│   ├── gen/             # 代码生成类页面
│   ├── flow/            # 流程类页面
│   ├── home/            # 首页/工作台
│   ├── knowledge/       # 知识库类页面
│   └── ...
├── api/                 # 按业务域组织的请求封装层
│   ├── admin/           # 系统管理接口
│   ├── app/             # 应用接口
│   ├── gen/             # 代码生成接口
│   └── ...
├── components/          # 全局复用组件与全局注册入口（index.ts）
├── hooks/               # 通用组合式能力
│   ├── table.ts         # useTable（分页查询核心）
│   ├── dict.ts          # useDict（字典加载）
│   ├── form.ts          # useForm
│   ├── message.ts       # useMessage / useMessageBox
│   ├── echarts.ts       # ECharts 封装
│   └── moduleFederation.ts  # 模块联邦
├── stores/              # Pinia 状态管理
├── styles/              # 全局样式入口
├── config/              # 站点、远程模块等配置
├── theme-core/          # 来自 aura-core，布局外壳、主题面板、导航等
└── utils/               # 工具函数（request.ts、other.ts、validate.ts 等）
```

---

## 核心模块边界

### 1. `views` — 页面层

职责：承载完整业务页面，组合查询区、表格区、图表区、弹窗区、抽屉区，调用 `api` 和 `hooks`。

判断原则：
- 只要是"一个可被路由直接打开的页面"，大概率放在 `views`
- 原型转码后的目标页面通常必须落到 `views`
- 每个业务模块建议单独一个子目录，内含 `index.vue`、`form.vue`（弹窗）、可选 `drawer.vue`（抽屉）

### 2. `router` — 路由入口层

职责：定义本地动态路由、初始化后端返回菜单路由、处理模块联邦远程页面加载。

判断原则：
- 大多数业务页面由**后端菜单**驱动，通过 `backEnd.ts` 动态加载，componentPath 对应 `src/views` 下的文件路径
- 本地 `dynamicRoutes` 适合补充页、手工验证页（目前只有 `/home`）
- 新页面开发阶段可先加入 `dynamicRoutes` 验证，联调后改为后端菜单管控

### 3. `api` — 请求封装层

职责：按业务域封装接口，统一调用 `request.ts`。

判断原则：
- 页面不应直接散写 axios 请求
- 即使是 mock 阶段，也建议先抽成 `api/*.ts` 形态
- 常见方法命名：`fetchList`（分页）、`getObj`（详情）、`addObj`（新增）、`putObj`（编辑）、`delObj`/`delObjs`（删除）

### 4. `hooks` — 逻辑复用层

常用 hooks：
- `useTable(state)` — 分页查询表格（详见查询表格页规范）
- `useDict('dictType')` — 字典加载
- `useMessage()` — 成功/失败/警告提示
- `useMessageBox()` — 确认弹窗
- `useEcharts(domRef)` — ECharts 图表初始化

### 5. `stores` — 全局状态层

判断原则：
- 纯页面局部状态必须留在页面内部
- 只有跨页面共享或与框架运行有关的状态才进入 store

### 6. `theme-core` — 外壳与主题层

来自 `aura-core`，负责提供布局外壳、主题配置、导航、锁屏等系统级能力。

判断原则：
- 页面本身通常只负责内容区，不负责整体壳布局
- 原型转码时不要在页面里重复造"系统级外壳"

---

## 工程入口与运行机制

### 1. 应用启动入口（`src/main.ts`）

关键流程：
1. 初始化防调试能力
2. 引入全局样式
3. 请求系统全局配置 `getSystemGlobalConfig`
4. 根据后端返回配置初始化主题
5. 创建 Vue 应用实例
6. 挂载 Pinia、Router、全局组件、i18n
7. 执行远程 i18n 初始化

### 2. 路由初始化机制

路由分三层：
- `staticRoutes` — 登录、OAuth 跳转等无需鉴权的静态路由
- `dynamicRoutes` — 本地补充路由（如首页 `/home`）
- 后端菜单返回路由 — 经 `backEnd.ts` 动态注册，`componentPath` 字段对应 `src/views` 文件路径

### 3. 请求运行机制（`src/utils/request.ts`）

关键能力：自动注入 Token、租户 ID、版本号；GET 参数加密；Body 加密；URL 自适配；统一处理登录过期/租户过期。

---

## 必须遵循

- 页面代码必须落在 `src/views`
- 请求必须抽到 `src/api`
- 常规列表页必须复用 `useTable`
- 通用能力必须复用现有 `components` 和 `hooks`
- 页面只管业务内容区，不重建系统级布局
- 统一遵循项目已有 `script setup + TypeScript + Element Plus` 风格
- 按钮权限使用 `v-auth="'permission_code'"` 指令控制

## 推荐写法

- 简单列表页：`index.vue + api.ts`
- 带弹窗/抽屉的列表页：`index.vue + form.vue + api.ts`
- 图表看板页：页面内组合卡片、图表和局部组件，依然走 `views` 页面组织
- 暂时没有真实接口时，先做与真实 `api` 形态一致的 mock 封装，不要把假数据直接散在模板里

## 常见文件拆分方式

| 文件 | 职责 |
|------|------|
| `index.vue` | 页面主容器，负责查询区、表格区、事件分发 |
| `form.vue` | 新增/编辑弹窗（dialog 形式） |
| `drawer.vue` | 详情抽屉或附属操作抽屉 |
| `api/*.ts` | 页面所需接口 |
| `i18n/` | 模块国际化文件 |

---
