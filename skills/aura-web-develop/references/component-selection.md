# 组件选型与模块联邦实现

## 通用组件选型

按“综合端全局组件/Hooks → Element Plus → 页面私有业务组件 → 跨业务公共组件”的顺序选型。业务 UI 需要进入 Element Plus 选型阶段时，必须先使用 Codex 内置浏览器访问 [Element Plus 组件总览](https://element-plus.org/zh-CN/component/overview)，再阅读候选组件的官方文档，核对当前项目版本支持的 Props、Events、Slots 和公开方法；存在满足需求或可通过官方组合方式满足需求的组件时优先采用。只有综合端全局组件/Hooks 和 Element Plus 均确实无法满足时，才允许自行编写 UI 组件，并在职责清单和交付中记录已核对的候选组件及不适用原因；不得仅凭记忆、个人偏好或样式差异跳过官方组件。地图、视频等专项能力仍按对应专项规范选型，不适用本通用顺序。

## 模块联邦组件加载

涉及 remote、expose、manifest、远程菜单、shared、运行时入口或模块联邦配置时，先检查 `aura-module-federation-check` 是否可用；缺失时提示用户安装。可用后先建立基线，由本技能完成实现后再次复检。远程页面不得依赖提供方 `main.ts` 的全局注册副作用；按需注册、组件库 Resolver 或自动导入组件由提供方优先通过编译期 Resolver 注入组件代码与 `sideEffects` 样式，宿主不得承担提供方组件库的安装和解析职责。必须从构建产物核验对应 JS import 与 CSS 依赖，并分别验证独立运行和远程加载，控制台不得出现 `Failed to resolve component`，组件容器尺寸和样式必须正常。Resolver 无法覆盖时才显式导入组件及配套样式，禁止只导入组件 JS。
