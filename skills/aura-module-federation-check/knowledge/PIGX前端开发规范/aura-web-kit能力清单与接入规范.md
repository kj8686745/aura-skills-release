# aura-web-kit 能力清单与接入规范

## 一、版本与选用原则

框架 **1.2.0** 验证基线：`@fxft/aura-web-kit@1.9.0`、`@fxft/aura-ui@1.1.2`、Element Plus `2.14.6`、VueUse `15.0.0`、Node.js `>=22.12.0`、TypeScript `5.9.3`、ESLint `8.57.1`、typescript-eslint parser/plugin `8.46.1`。核对日期：2026-10-21。下表依据已安装发布包的 `package.json.exports` 与 `.d.ts` 整理，覆盖 **113 个公开子入口**；本规范以 web-kit 精确版本 `1.9.0` 为准，核对依赖声明、锁文件与实际安装版本一致；不将更高版本自动视为符合本基线，也不把源码仓库较新版本当作项目已可用能力。

新增或修改公共 TS 时，先按场景查表，再读相应入口的声明和实现。包没有根入口；使用 `@fxft/aura-web-kit/<子路径>`，不引用 `src/`、`dist/` 或未导出的内部模块。表中列出主要导出用于检索，具体参数和完整导出以该版本声明为准。

- 无项目依赖的工具、`useForm`、`usePermissions` 可直接从公共包导入。
- 消息、表格、字典、参数等依赖请求/Pinia/i18n 的 Hook 使用项目已创建的绑定；不要在页面重新创建工厂或误用缺少上下文的底层 Hook。
- 工具、Hook、运行时算法和构建兼容修复若适合跨项目，统一进入 web-kit，显式接收依赖；项目保留实例、环境参数、资源路径和业务逻辑。
- 公共包修改完成对应测试、发布包消费验证、使用项目验证并同步清单；版本升级沿项目发布流程执行。

## 二、业务导入与项目绑定

| 场景 | 页面/API 使用入口 | 绑定职责 |
| --- | --- | --- |
| 请求 | `/@/config/aura/request` 默认导出 | 项目请求、认证、地图/参数 API 绑定；业务不直接创建 Axios |
| 表格、消息、字典、参数 | `/@/config/aura/index` | `useTable`、`useMessage`、`useMessageBox`、`useDict`、`useParam`；共享本项目 auraContext |
| 表单 | `@fxft/aura-web-kit/hooks/form` | `useForm` 与 `FormRef`，无需项目请求 |
| 权限 | `@fxft/aura-web-kit/hooks/permissions` | 读取宿主提供的权限上下文，不能自建空权限默认值 |
| 登录与用户状态 | `/@/config/aura/account` | 登录 API、OAuth、用户 Store |
| 存储、认证、令牌 | `/@/config/aura/storage`、`auth`、`tokenCheck` | systemId、退出策略与令牌监测 |
| 图表、下载、混合工具 | `/@/config/aura/echarts`、`download`、`utilities` | 图表空态图片、请求下载及项目资源 |
| 联邦加载、语言、样式 | `/@/config/aura/federation` | enhanced runtime、远程 entries、Provider、scope |
| 资源地址 | `/@/hooks/moduleFederation` | 绑定提供方自身 `import.meta.url` 与 remoteEntryName |
| 浏览器属性、事件、构建信息 | `/@/config/aura/browser` | 项目环境、Router、构建信息与总线 |
| 路由 | `/@/router/index` | 项目 Router 和菜单/Store 实例 |

```ts
import request from '/@/config/aura/request';
import { useTable, useDict, useMessage, useMessageBox } from '/@/config/aura/index';
import type { BasicTableProps } from '@fxft/aura-web-kit/hooks/table';
import { useForm } from '@fxft/aura-web-kit/hooks/form';
import { usePermissions } from '@fxft/aura-web-kit/hooks/permissions';
import { handleTree } from '@fxft/aura-web-kit/utils/tree';
```

项目 `src/config/aura/index.ts` 使用 `createAuraFrameworkContext({ request, pinia, getLocale })`，再以 `createTableHook/createMessageHooks/createDictHook/createParamHook` 生成绑定。配置不放入模块级跨应用可变默认对象。

Vite 与 TypeScript 仅保留 `/@` 源码映射；旧 `/@/utils/request`、`/@/hooks/message`、`/@/hooks/form` 等是历史入口，1.2.0 新代码直接引用上表，不新增迁移 alias。本规范只面向 1.2.0，不提供旧路径兼容；迁移需同时完成实例绑定与调用入口。

## 三、公开子入口清单

表内入口统一省略 `@fxft/aura-web-kit` 前缀。运行环境“浏览器”表示运行时入口；其中纯工具可无 DOM 使用，仍需核对签名与依赖。“类型”入口按类型/声明消费。“Node 构建”入口不能进入浏览器依赖图。

### 常用 Hook 与服务

| 公开入口 | 主要导出或类型 | 用途 | 运行环境 / 绑定要求 |
| --- | --- | --- | --- |
| `/api/params` | `configureParamRequest` | 参数请求适配 | 浏览器 |
| `/hooks/common` | `createCommonHook` | 项目常用工具绑定 | 浏览器 |
| `/hooks/map-config` | `DEFAULT_MAP_CENTER`、`configureMapRequest`、`loadMapConfig`、`loadMapCenter` | 地图配置与请求绑定 | 浏览器 |
| `/hooks/form` | `useForm` | 表单校验、重置、清理校验 | 浏览器 |
| `/hooks/permissions` | `PERMISSION_CONTEXT_KEY`、`createPermissionContext`、`usePermissions` | 权限上下文与权限判断 | 浏览器 |
| `/runtime` | `AURA_CONTEXT_KEY`、`createAuraContext`、`captureAuraContext`、`provideAuraContext` | 应用上下文与服务契约 | 浏览器 |
| `/framework` | `createAuraFrameworkContext` | 框架请求、Pinia、语言服务预设 | 浏览器；使用项目绑定 |
| `/api/common` | `createCommonApi` | 字典与参数 API 工厂 | 浏览器 |
| `/hooks/table` | `useTable`、`createTableHook`、`PageQuery`、`PageResult<T>`、`OrderItem` | 标准 current/size 分页、排序、查询 | 浏览器；使用项目绑定 |
| `/hooks/message` | `createElementPlusMessageServices`、`useMessage`、`useMessageBox`、`createMessageHooks` | 消息、确认框与重复合并 | 浏览器；使用项目绑定 |
| `/hooks/dict` | `createDictHook`、`useDict` | 字典查询与缓存 | 浏览器；使用项目绑定 |
| `/hooks/param` | `createParamHook`、`useParam` | 系统参数查询与缓存 | 浏览器；使用项目绑定 |
| `/hooks/echarts` | `isChartDataEmpty`、`useECharts`、`createEChartsHook` | 图表生命周期、空态与 resize | 浏览器；使用项目绑定 |
| `/api/login` | `LoginTypeEnum`、`LoginErrorEnum`、`SocialLoginEnum`、`createLoginApi` | 登录 API 工厂与枚举 | 浏览器 |

### 请求、认证与存储

| 公开入口 | 主要导出或类型 | 用途 | 运行环境 / 绑定要求 |
| --- | --- | --- | --- |
| `/http/preset` | `createFrameworkHttpOptions` | 框架请求预设 | 浏览器；使用项目绑定 |
| `/auth/framework` | `createFrameworkAuth` | 框架认证策略 | 浏览器；使用项目绑定 |
| `/http/service` | `createRequestClient` | Axios 实例工厂 | 浏览器；使用项目绑定 |
| `/storage` | `STORAGE_KEYS`、`createAuraStorage` | 按系统隔离的 Local、Session、Cookie | 浏览器；使用项目绑定 |
| `/http` | `createAuraRequest`、`createLazyRequest`、`CommonHeaderEnum`、`adaptRequestUrl` | 请求门面、懒加载与公共头 | 浏览器；使用项目绑定 |
| `/http/crypto` | `encryptRequestText`、`decryptRequestText`、`createApiCrypto` | 请求加解密 | 浏览器；使用项目绑定 |
| `/auth` | `REQUEST_AUTH_ERROR_EVENT`、`createAuthController`、`dispatchRequestAuthError` | 认证错误事件与退出控制 | 浏览器；使用项目绑定 |
| `/auth/token-check` | `createTokenMonitor`、`useTokenCheck` | 令牌监测生命周期 | 浏览器；使用项目绑定 |

### 联邦、路由、国际化与启动

| 公开入口 | 主要导出或类型 | 用途 | 运行环境 / 绑定要求 |
| --- | --- | --- | --- |
| `/i18n/runtime` | `mergeLocaleMessages`、`flatLocaleMessages`、`createAuraI18nRuntime` | 项目语言合并、初始化与销毁 | 浏览器 |
| `/router` | `createAuraRouterRuntime`、`createRouterApi`、`formatMenuTree` | 路由初始化与菜单运行时 | 浏览器；使用项目绑定 |
| `/router/utils` | `formatFlatteningRoutes`、`formatTwoStageRoutes`、`getFirstAccessibleMenuPath`、`dynamicImport` | 路由树、权限过滤与动态导入 | 浏览器；使用项目绑定 |
| `/config/site` | `createSiteConfig` | 站点配置工厂 | 浏览器 |
| `/federation/config` | `AURA_FRONTEND_SERVICE_NAME_KEY`、`defaultI18nScanDirs`、`federationExposeDefaults`、`getRemoteScopeClass` | 联邦默认配置、scope 与身份上下文 | 浏览器；配置或 runtime 适配 |
| `/federation` | `createFederationRemotes`、`createFederationI18n`、`createFederationStyles`、`createFederationRegistry` | 远程注册、样式、语言和页面加载工厂 | 浏览器；配置或 runtime 适配 |
| `/federation/retry` | `getRemoteAutoRetryDelays`、`getRemoteLoadErrorMessage`、`isTransientRemoteLoadError`、`waitForRemoteRetry` | 远程失败识别与重试间隔 | 浏览器 |
| `/i18n` | `auraMessages`、`normalizeAuraLocale`、`createAuraTranslator` | 库内语言与翻译 | 浏览器 |
| `/bootstrap` | `createAuraBootstrap` | 启动缓存恢复与系统配置刷新 | 浏览器；使用项目绑定 |

### 浏览器工具

| 公开入口 | 主要导出或类型 | 用途 | 运行环境 / 绑定要求 |
| --- | --- | --- | --- |
| `/browser/config-manager` | `createConfigManager` | 浏览器配置管理 | 浏览器 |
| `/browser/build-info` | `createBuildInfoReporter` | 构建信息报告 | 浏览器 |
| `/browser/iconfont-list` | `createIconfontList` | 字体图标列表 | 浏览器 |
| `/browser/title` | `createTitleHooks` | 页面标题绑定 | 浏览器 |
| `/browser/window` | `openWindow`、`getQueryString` | 窗口与地址查询 | 浏览器 |
| `/browser/loading` | `NextLoading` | 页面加载状态 | 浏览器 |
| `/browser/anti-debug` | `createAntiDebug` | 反调试驱动 | 浏览器 |
| `/browser/app-properties` | `createAppProperties` | 应用属性绑定 | 浏览器 |
| `/browser/url` | `getBrowserOrigin`、`getBrowserFullUrl`、`getBrowserApiUrl` | 浏览器地址解析 | 浏览器 |
| `/browser/watermark` | `default` | 页面水印 | 浏览器 |
| `/browser/markdown` | `fetchRemoteMdFile` | 远程 Markdown 读取 | 浏览器 |
| `/browser/iconfont` | `getIconfontSources`、`parseIconfontSources`、`inspectIconfontCss`、`createIconfontService` | 字体源、CSS 解析与加载 | 浏览器 |
| `/browser/assets` | `createFederationAssets` | 提供方资源根路径与样式 URL | 浏览器；传入提供方 URL |
| `/browser/events` | `createEventBus` | 实例事件总线 | 浏览器 |
| `/browser/download` | `saveBlobFile`、`createDownloadService`、`handleBlobFile`、`downBlobFile` | 文件下载与响应处理 | 浏览器 |
| `/browser/xlsx` | `createXlsxBlob` | 工作簿 Blob 与列宽 | 浏览器 |

### 纯工具与格式处理

| 公开入口 | 主要导出或类型 | 用途 | 运行环境 / 绑定要求 |
| --- | --- | --- | --- |
| `/utils/image` | `applyImageFallback` | 图片失败降级 | 浏览器 |
| `/utils/requestData` | `normalizeJsonRequestData` | JSON 请求数据归一化 | 浏览器 |
| `/utils/framework` | `createFrameworkUtilities` | 混合工具实例绑定 | 浏览器 |
| `/utils/empty-text` | `formatEmptyText` | 空文本格式化 | 浏览器 |
| `/utils/phoneMask` | `isValidContactPhone`、`maskContactPhone` | 手机号校验与脱敏 | 浏览器 |
| `/utils/importValidation` | `getImportValidationRowValue` | 导入错误行读取 | 浏览器 |
| `/utils/authFunction` | `auth`、`auths`、`authAll` | 权限函数 | 浏览器 |
| `/utils/errorCode` | `default` | 错误码映射 | 浏览器 |
| `/utils/coordinate` | `transformCoordinate`、`toAmapCoordinate`、`fromAmapCoordinate` | 坐标转换 | 浏览器 |
| `/utils/string` | `toUnderline` | 字符串命名转换 | 浏览器 |
| `/utils/array` | `judgmentSameArr`、`removeDuplicate`、`isObjectValueEqual` | 数组去重与对象比较 | 浏览器 |
| `/utils/tree` | `handleTree` | 树形结构转换 | 浏览器 |
| `/utils/uuid` | `generateUUID` | UUID 生成 | 浏览器 |
| `/utils/params` | `serializeRequestParams` | 请求参数序列化 | 浏览器 |
| `/utils/date` | `dateTimeStr`、`dateStr`、`timeStr`、`formatDateStandard` | Day.js 日期格式与兼容接口 | 浏览器 |
| `/utils/validate` | `validateNull`、`rule`、`getRegExp` | 表单校验规则 | 浏览器 |
| `/utils/tools-validate` | `verifyNumberPercentage`、`verifyNumberPercentageFloat`、`verifyNumberIntegerAndFloat`、`verifiyNumberInteger` | 输入校验与处理 | 浏览器 |

### 指令与 Store

| 公开入口 | 主要导出或类型 | 用途 | 运行环境 / 绑定要求 |
| --- | --- | --- | --- |
| `/directive` | `directive` | 公共指令安装 | 浏览器 |
| `/directive/authDirective` | `authDirective` | 权限指令 | 浏览器 |
| `/directive/customDirective` | `wavesDirective` | 波纹指令 | 浏览器 |
| `/directive/focus` | `focusDirective` | 聚焦指令 | 浏览器 |
| `/directive/loadingScrollLock` | `loadingScrollLockDirective` | 加载态滚动锁 | 浏览器 |
| `/stores/dict` | `dict` | 字典缓存 Store | 浏览器 |
| `/stores/param` | `param` | 参数缓存 Store | 浏览器 |
| `/stores/userInfo` | `createUserInfoStore` | 用户信息 Store 工厂 | 浏览器 |
| `/stores/tagsViewRoutes` | `createTagsViewRoutesStore` | 标签路由 Store 工厂 | 浏览器 |
| `/stores/routesList` | `useRoutesList` | 路由列表 Store | 浏览器 |
| `/stores/requestOldRoutes` | `useRequestOldRoutes` | 历史请求路由 Store | 浏览器 |
| `/stores/keepAliveNames` | `useKeepALiveNames` | 缓存组件名 Store | 浏览器 |
| `/stores/msg` | `useMsg` | 消息 Store | 浏览器 |

### 主题内部公共 TS

供核心主题维护和明确需要该公开能力的场景使用；布局 Vue、样式、资源和远程契约仍由 aura-core 提供，业务不据此复制主布局。

| 公开入口 | 主要导出或类型 | 用途 | 运行环境 / 绑定要求 |
| --- | --- | --- | --- |
| `/theme-core/types/layout` | `AsideState`、`ColumnsAsideState`、`BreadcrumbState`、`SearchState` | 布局状态类型 | 类型 / 声明；核心按需绑定 |
| `/theme-core/utils/device` | `isMobileDevice` | 移动设备判断 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/useHorizontalWheelScroll` | `useHorizontalWheelScroll` | 横向滚轮 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/usePageZoom` | `PAGE_ZOOM_MIN`、`PAGE_ZOOM_MAX`、`PAGE_ZOOM_STEP`、`PAGE_ZOOM_DEFAULT` | 页面缩放与坐标换算 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/useUIState` | `useUIState` | 布局 UI 状态 | 浏览器；核心按需绑定 |
| `/theme-core/stores/layout` | `useLayoutStore` | 布局 Store | 浏览器；核心按需绑定 |
| `/theme-core/layout/navMenu/menuIconVisibility` | `shouldShowMenuIcon` | 菜单图标显隐 | 浏览器；核心按需绑定 |
| `/theme-core/constants/themeDefaults` | `createThemeDefaults` | 主题默认值工厂 | 浏览器；核心按需绑定 |
| `/theme-core/utils/lockScreenState` | `createLockScreenState` | 锁屏状态工厂 | 浏览器；核心按需绑定 |
| `/theme-core/utils/theme-manager` | `createThemeManager` | 主题管理工厂 | 浏览器；核心按需绑定 |
| `/theme-core/utils/theme` | `createThemeColors` | 主题颜色工厂 | 浏览器；核心按需绑定 |
| `/theme-core/utils/themeCssVariables` | `createThemeCssVariables` | 主题 CSS 变量工厂 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/useThemeConfigStorage` | `createThemeConfigStorage` | 主题配置存储绑定 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/useFontSize` | `createFontSize` | 字体大小绑定 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/useThemeColorPicker` | `createThemeColorPicker` | 主题选色绑定 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/useThemeFilters` | `createThemeFilters` | 主题滤镜绑定 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/useFaviconManager` | `createFaviconManager` | 站点图标绑定 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/useTemplateSelection` | `createTemplateSelection` | 布局模板选择 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/useTemplateManagement` | `createTemplateManagement` | 布局模板管理 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/useLoginTemplateSelection` | `createLoginTemplateSelection` | 登录模板选择 | 浏览器；核心按需绑定 |
| `/theme-core/hooks/useThemeRuntime` | `createThemeRuntime` | 主题运行时工厂 | 浏览器；核心按需绑定 |
| `/theme-core/stores/themeConfig` | `createThemeConfigStore` | 主题 Store 工厂 | 浏览器；核心按需绑定 |
| `/theme-core/stores/login` | `createLoginStore` | 登录界面 Store 工厂 | 浏览器；核心按需绑定 |
| `/theme-core/theme/font` | `createThemeFont` | 主题字体工厂 | 浏览器；核心按需绑定 |
| `/theme-core/contracts` | `LayoutTemplateKey` | 主题绑定契约 | 类型 / 声明；核心按需绑定 |
| `/theme-core/config-manager` | `createConfigManager` | 主题缓存恢复与应用 | 浏览器；核心按需绑定 |

### 类型与声明

| 公开入口 | 主要导出或类型 | 用途 | 运行环境 / 绑定要求 |
| --- | --- | --- | --- |
| `/types/state` | `UserInfosState`、`KeepAliveNamesState`、`RequestOldRoutesState`、`TagsViewRoutesState` | 公共状态类型 | 类型 / 声明 |
| `/types/axios` | `声明扩展` | Axios 声明扩展 | 类型 / 声明 |
| `/types/assets` | `default` | 静态资源声明 | 类型 / 声明 |
| `/types/remote-core` | `default` | 精确核心远程声明 | 类型 / 声明 |
| `/types` | `RouteItem`、`RouteToFrom`、`RouteItems`、`RefType` | 公共接口与类型 | 类型 / 声明 |
| `/types/ambient` | `声明扩展` | 环境全局声明 | 类型 / 声明 |
| `/types/vue` | `声明扩展` | Vue 类型扩展 | 类型 / 声明 |

### 构建端

| 公开入口 | 主要导出或类型 | 用途 | 运行环境 / 绑定要求 |
| --- | --- | --- | --- |
| `/vite/component-overrides` | `createComponentOverrideResolver` | 本地组件编译期覆盖 | Node 构建 |
| `/vite` | `generateI18nImports`、`createGitBuildInfo`、`auraAutoOptimizeDeps`、`createAuraAutoImportPreset`、`pruneFederationSsrImports`、`stabilizeFederationDevOptimizer` | 语言生成、自动导入、预构建和联邦构建插件 | Node 构建 |
| `/postcss` | `createAuraPostcssPlugins` | Tailwind scope 与样式兼容插件 | Node 构建 |

## 四、构建与 UI 配套

Vite 使用 `/vite` 的 `auraAutoOptimizeDeps`，复用实际组件 resolver 工厂、`createAuraAutoImportPreset` 映射与 exposes；不再展开固定全量预构建清单。移除 `stabilizeFederationModuleScan`，保留 SSR 清理、dev 优化和远程预加载跳过插件。PostCSS 沿用 `/postcss` 的 `createAuraPostcssPlugins`。TypeScript 配套工具链、配置和冷启动取证见模块联邦规范的“工具链与自动预构建基线（2026-10-21）”。

公共 UI 不属于 web-kit；使用 aura-ui 的 `AuraUIResolver` 和 `provideAuraUiConfig`，见 《组件复用与公司基础组件库规范》。地图、视频按业务需要接入 ui-plus。

## 五、1.6.15 使用要点
+
+- `SocialLoginEnum.ALIPAY` 已是 `/api/login` 的公共枚举项；登录协议由 `createLoginApi` 与用户 Store 使用，不在项目扩展同名枚举。
+- `createAuraAutoImports` 包含 `LoginTypeEnum`、`LoginErrorEnum`、`SocialLoginEnum` 的按需运行时导入；类型由 `/types/ambient` 提供。自动导入与类型声明都需接入，不能只写全局类型而缺少运行时值。
+- `/browser/loading` 的 `NextLoading.start/done` 统一遮罩生命周期，公共路由在导航结束后关闭 loading。失败远程页应在内容区呈现重试状态；不要在项目复制遮罩去重或延迟关闭补丁。
+- 联邦失败路径验收包含首次进入不可用远程页面时遮罩能结束，宿主与远程包副本不会相互误关新一轮 loading。
+
+## 六、维护与核对

1. 从目标项目的 package.json、锁文件和已安装 `@fxft/aura-web-kit/package.json` 确认版本。
2. 对比 `exports` 与本表子入口；逐项核对 `.d.ts`、导出类型、运行环境和工厂所需依赖。不要直接把源码文件列表当公共 API。
3. 更新版本说明、场景映射和受影响示例；公开名称变化须验证使用处。新增清单项不能自动授权项目升级依赖。
4. 正式源维护于 nexus 的 `docs/PIGX前端开发规范`；同步两个技能引用的快照，并运行技能校验。技能入口只维护选用原则与导航，不重复罗列全部能力。
