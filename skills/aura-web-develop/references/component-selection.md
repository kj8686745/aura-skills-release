# 组件选型与模块联邦实现

## 通用组件选型

Aura UI 目前有 **39 个公开组件**，从[组件索引](../knowledge/PIGX前端开发规范/aura-ui组件库/README.md)按用途选型，只读本次使用组件的示例、Props、事件、插槽和公开方法。Resolver、样式及服务绑定见[公共接入](../knowledge/PIGX前端开发规范/aura-ui能力清单与接入规范.md)。日常开发按文档接入，不要求逐项审计包 exports、Resolver 源码或构建产物；仅升级依赖、遇到契约差异或接入异常时核对实际安装包。演示数据和文案替换为项目真实接口、字典和 i18n。

按“aura-web-kit 公共 Hook / aura-ui 公共组件 → Element Plus → 必要的自定义基础 UI”核对通用能力，地图、视频等专项能力按对应规范使用公司组件。公开入口与项目绑定见 [能力清单](../knowledge/PIGX前端开发规范/aura-web-kit能力清单与接入规范.md)。进入 Element Plus 选型阶段时，按需查阅[官方组件总览](https://element-plus.org/zh-CN/component/overview)和候选组件文档，并核对当前安装版本的类型与公开 API；资料可通过当前可用的文档工具读取，需要交互取证时再使用浏览器，不固定工具或要求局部任务重读整个总览。

可复用的基础 UI 优先采用公共组件，不重复实现已有能力。页面私有业务组件可组合 Aura UI、Element Plus 和业务数据，按职责、所有权和复用收益组织，不以“Element Plus 可以组合实现”为由禁止封装。只有确需新写基础控件时，才在既有开发记录中简记已核对能力和不适用原因，不为普通业务组合新增选型报告。

组件 JS 与 CSS 均按需引入：模板优先 `AuraUIResolver`，脚本组件对象使用公开子入口；公共类型可用根入口 `import type`。本技能面向的项目均已接入 Core，统一使用 `AuraUIResolver({ injectGlobal: false })` 并保留默认组件 CSS。服务通过 `@fxft/aura-ui/config` 绑定，不新增全量注册或 Aura UI 全量样式；详细边界及包产物限制见[公共接入](../knowledge/PIGX前端开发规范/aura-ui能力清单与接入规范.md#按需解析)。

## 地图组件

Aura 地图使用 `@fxft/ui-plus` 的 `FxftMap`，按 [FxftMap 组件接入](fxft-map-integration.md)核对 Resolver/样式、有效高度、初始化 Props 和组件 `load` 时机。中心、缩放、默认底图及底图集合来自公共 `loadMapConfig()`，专项模板中的示例值不覆盖系统配置；点位、详情地图和选点等再按可用的 `fmap-2d` 对应资料实现。

## 选择器候选规模

选择器先按[候选规模契约](query-select-contract.md#选择器按候选规模选型)判断：候选较大、无明确上限或可能增长时必须虚拟化；小规模且上限明确时可用普通组件。远程搜索/分页不能代替大结果集虚拟渲染，公开契约和运行窗口均须核对。

## 模块联邦组件加载

涉及 remote、expose、manifest、远程菜单、shared、运行时入口或模块联邦配置时，先检查 `aura-module-federation-check` 是否可用；缺失时提示用户安装。可用后先建立基线，由本技能完成实现后再次复检。远程页面不得依赖提供方 `main.ts` 的全局注册副作用；按需注册、组件库 Resolver 或自动导入组件由提供方优先通过编译期 Resolver 注入组件代码与 `sideEffects` 样式，宿主不得承担提供方组件库的安装和解析职责。必须从构建产物核验对应 JS import 与 CSS 依赖，并分别验证独立运行和远程加载，控制台不得出现 `Failed to resolve component`，组件容器尺寸和样式必须正常。Resolver 无法覆盖时才显式导入组件及配套样式，禁止只导入组件 JS。
