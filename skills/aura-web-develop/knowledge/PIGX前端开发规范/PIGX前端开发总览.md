# PIGX 前端开发总览

## 一、项目定位

PIGX 模块联邦（综合端）是基于 Vue 3 的模块联邦前端项目。它既能独立运行，也能作为提供方把页面、组件、API、工具、国际化和样式暴露给其他综合端，同时作为消费方加载 `aura-core` 或业务远程模块。

它不是 iframe，也不是把所有业务打入一个大包。远程页面加载时不会执行提供方的 `index.html` 和 `main.ts`，因此全局注册、国际化、样式和静态资源必须按模块联邦规则适配。需要覆盖自动解析的第三方组件时，必须在提供方构建阶段通过 Vite Resolver 注入本地 import，不能依赖 `main.ts` 的同名全局组件替换。

## 二、技术栈

| 分类 | 当前实现 |
| --- | --- |
| 视图 | Vue 3.5、TypeScript、`<script setup>` |
| 构建 | Vite 6、pnpm 10、Node.js 20.12 及以上 |
| UI | Element Plus 2.14.3，Module Federation singleton |
| 状态与路由 | Pinia 2、Vue Router 4 |
| 国际化 | Vue I18n 9 |
| 请求 | Axios，经 `/@/utils/request` 懒加载封装 |
| 模块联邦 | `@module-federation/vite@1.18.2`、`@module-federation/enhanced@2.8.0` |
| 样式 | SCSS、Tailwind CSS、主题 CSS 变量、远程 scoped Tailwind |

禁止恢复 `@originjs/vite-plugin-federation`、`vite-plugin-top-level-await` 或旧静态远程注册表。

## 三、启动和构建

```bash
node --version
pnpm --version
pnpm install --frozen-lockfile
pnpm dev
pnpm build
```

模板要求 Node.js 20.12 及以上。包管理器以 `packageManager` 和 `pnpm-lock.yaml` 为准，不混用 npm、yarn。

## 四、目录职责

```text
src/
├── api/          # 按业务域封装后端接口
├── assets/       # 参与 Vite 构建的图片、SVG、字体等
├── components/   # 模块联邦（综合端）全局或跨业务复用组件
├── config/       # 站点和模块联邦配置
├── hooks/        # useTable、模块联邦等组合能力
├── i18n/         # 本地及模块联邦语言包聚合
├── router/       # 静态路由、补充路由、后端菜单解析
├── stores/       # Pinia 状态
├── styles/       # 全局、Tailwind 和远程隔离样式
├── utils/        # 请求、资源、文件等通用能力
└── views/        # 可由路由或模块联邦直接加载的业务页面
```

后台主布局、主题运行时和布局预设由 `aura-core/theme-core` 提供，模块联邦（综合端）不维护本地 `src/theme-core` 副本。

### 业务边界

- 页面放在 `views/<业务域>/`，页面内部组件放在同目录 `components/`。
- 后端接口放在 `api/<业务域>/`，页面不得内联大段请求配置。
- 跨页面复用逻辑优先放在业务 hooks；真正通用后再提升到 `src/hooks`。
- 只在多个业务域复用的组件才进入 `src/components`。

## 五、应用运行链路

```text
main.ts
→ 恢复启动缓存、主题和 Iconfont
→ 从 aura-core manifest 确保核心框架主题样式
→ 获取系统全局配置并校准 systemId、主题和 Iconfont
→ 创建 Vue 应用
→ 注册 Pinia、Router、模块联邦（综合端）全局组件和 i18n
→ 后端菜单转换为动态路由
→ 本地加载或模块联邦加载页面
```

`src/utils/request.ts` 保持原调用接口，但首次真实请求才加载请求内核。认证失效由独立处理器解耦，业务页面不自行清 Token 或跳转登录。

## 六、后台布局预设与布局模式

后台布局由 `aura-core` 统一维护，业务项目只选择框架已有能力：

- 布局预设：自定义、经典蓝、草木绿。
- 底层布局模式：`defaults`、`classic`、`transverse`、`columns`。

布局预设负责一组完整的主题和布局配置，布局模式负责顶栏、侧栏和菜单的基础结构。业务页面可以自由实现内容区内部布局，但不得复制 `aura-core/theme-core`、替换后台主布局或私自增加布局预设。现有能力不满足时按[开发边界说明](./开发边界说明.md)提出框架需求。

## 七、路由和菜单

- `staticRoutes`：登录、OAuth、401、404 等公共页面。
- `dynamicRoutes`：首页、个人中心等本地补充路由。
- 后端菜单：绝大多数业务页面的正式入口。
- 模块联邦菜单：`componentPath` 带 `?type=moduleFederation`，由运行时加载远程 expose。

远程菜单示例：

```text
/aura-order-web/views/order/list/index.vue?type=moduleFederation
```

详见[路由与菜单规范](./路由与菜单规范.md)和[模块联邦规范](./模块联邦开发技术规范.md)。

## 八、开发优先级

1. 复用模块联邦（综合端）已有页面模式、Hooks 和全局组件。
2. 使用 Element Plus 组合业务页面。
3. 以上均无法满足时再开发业务组件。

`@fxft/ui-plus` 不属于普通业务 UI 的通用优先复用层级。地图和视频属于专项能力，仍按专项规范使用对应组件且不重复封装底层 SDK，详见[2D 地图开发规范](./2D地图开发规范.md)和[视频开发规范](./视频开发规范.md)。

## 九、每个页面必须具备

- 加载态、空态、错误态或明确的不适用说明。
- 按钮权限、表单校验和提交防重复。
- 使用主题变量，不硬编码主题色。
- 独立运行和远程运行均正确。
- 静态资源请求指向资源提供方，无部署前缀硬编码。
- 通过对应页面模式和[开发检查清单](./开发检查清单.md)。
