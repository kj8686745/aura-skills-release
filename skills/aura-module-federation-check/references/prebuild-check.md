# 开发依赖预构建检查

检查针对 Vite dev 首次访问动态菜单时的依赖发现，不等同于生产构建或 Tree Shaking。已安装组件库、构建成功、热缓存下切换正常都不能证明冷启动无重载。

## 核对流程

1. 核对真实源码使用、resolver 输出、已安装包版本与公开可解析入口；同时检查直接 import、自动导入、expose 映射及按需子路径。
2. 检查最终 `optimizeDeps.include/exclude/entries`，优先使用 `@fxft/aura-web-kit/vite` 的 `auraAutoOptimizeDeps` 自动收集实际使用入口。根包被 include 不代表所有子路径都覆盖；扫描到组件标签不代表已扫描到 resolver 后续注入的 import。
3. 对照 [入口登记](prebuild-entries.json)。仅检查当前项目实际使用的入口；未使用的组件不要求加入。已接入自动发现或配置由公共函数、spread、通配符、分文件生成时，核对发现报告与最终解析结果，不能只凭静态脚本 warning 判定缺失。
4. 冷启动或在项目专属缓存中重建预构建后，访问实际菜单并往返切换。记录 `new dependencies optimized`、`optimized dependencies changed. reloading`、WS `full-reload` 和页面 `performance.timeOrigin`。区分人工刷新、源码变更 HMR 与依赖补扫；构建/preview 不能替代 dev 验证。
5. qiankun 与独立模式配置不同应分别核对，避免共用不兼容缓存。联邦虚拟模块 owner 的旧缓存失效与新增组件依赖补扫是两类问题，分别定位，不用关闭 HMR 或屏蔽日志代替修复。

## 后续登记

新发现需参与预构建的公共依赖，应补充入口登记中的包名、组件/使用标记、精确入口、验证版本和证据，并更新相关检查及回归。区分“已配置候选”与“已复现需预构建”。包升级后重新核对 exports/resolver；不沿用失效私有路径。

跨项目公共构建机制优先收录 web-kit，项目只提供实际使用的入口或映射。清单是审计知识，不自动全量加入每个项目，不将业务页面或权限码收录为公共预构建要求。纯类型、Node 构建入口与未配置远程不得加入浏览器预构建。

## MF Vite 1.23.5 冷启动复核补充

- 异步全局组件、Markdown/代码编辑器等直接 import 的精确入口也按登记检查，不只检查 UI resolver。根据真实使用选择入口，不全量复制登记。
- 检查最终预构建元数据不得包含 web-kit 的 vite 或 types 入口；源码工具扫描带入这些入口时排除，不能为了消除补优化日志将其加入 include。
- 对照冷启动日志、首次菜单访问和往返后的 timeOrigin/full-reload；记录已复现缺失与修复后验证，已有样式/类型错误单独说明。

## web-kit 1.9.0 自动发现

预扫描与 Components 共用相同顺序的 resolver 工厂，每次创建独立实例；与 AutoImport 共用 createAuraAutoImportPreset 映射，并传入实际 exposes。onDiscover 的 discoveries/include/skippedFiles 与最终 optimizeDeps、预构建元数据一起作为覆盖证据。缺少字面量 include 不能判为缺失，检测到插件名称也不能判为运行通过。动态拼接、解析跳过和其他插件后续注入入口需单独补证，必要时只补精确例外。移除 stabilizeFederationModuleScan；旧 auraOptimizeDeps/getAuraOptimizeDeps 仍公开，但自动模式不要求展开全量清单。
