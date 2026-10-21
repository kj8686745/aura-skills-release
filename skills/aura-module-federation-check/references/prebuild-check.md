# 开发依赖预构建检查

检查针对 Vite dev 首次访问动态菜单时的依赖发现，不等同于生产构建或 Tree Shaking。已安装组件库、构建成功、热缓存下切换正常都不能证明冷启动无重载。

## 核对流程

1. 核对真实源码使用、resolver 输出、已安装包版本与公开可解析入口；同时检查直接 import、自动导入、expose 映射及按需子路径。
2. 检查最终 `optimizeDeps.include/exclude/entries`，优先复用 `@fxft/aura-web-kit/vite` 公共清单。根包被 include 不代表所有子路径都覆盖；扫描到组件标签不代表已扫描到 resolver 后续注入的 import。
3. 对照 [入口登记](prebuild-entries.json)。仅检查当前项目实际使用的入口；未使用的组件不要求加入。配置由公共函数、spread、通配符或分文件生成时核对最终解析结果，不能只凭静态脚本 warning 判定缺失。
4. 冷启动或在项目专属缓存中重建预构建后，访问实际菜单并往返切换。记录 `new dependencies optimized`、`optimized dependencies changed. reloading`、WS `full-reload` 和页面 `performance.timeOrigin`。区分人工刷新、源码变更 HMR 与依赖补扫；构建/preview 不能替代 dev 验证。
5. qiankun 与独立模式配置不同应分别核对，避免共用不兼容缓存。联邦虚拟模块 owner 的旧缓存失效与新增组件依赖补扫是两类问题，分别定位，不用关闭 HMR 或屏蔽日志代替修复。

## 后续登记

新发现需参与预构建的公共依赖，应补充入口登记中的包名、组件/使用标记、精确入口、验证版本和证据，并更新相关检查及回归。区分“已配置候选”与“已复现需预构建”。包升级后重新核对 exports/resolver；不沿用失效私有路径。

跨项目公共构建机制优先收录 web-kit，项目只提供实际使用的入口或映射。清单是审计知识，不自动全量加入每个项目，不将业务页面或权限码收录为公共预构建要求。纯类型、Node 构建入口与未配置远程不得加入浏览器预构建。
