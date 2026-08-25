# aura-core 模块联邦消费说明

完整规则以以下资料为准：

- `../knowledge/PIGX前端开发规范/模块联邦开发技术规范.md`
- 当前项目 `src/config/moduleFederation.ts`
- 当前项目模块联邦运行时加载器和类型声明

## 当前架构

- 使用 `@module-federation/vite` 与 `@module-federation/enhanced`。
- `aura-core` 提供布局、主题和公共能力，模板默认作为消费方加载。
- 禁止恢复 `@originjs/vite-plugin-federation`、`vite-plugin-top-level-await` 或旧静态远程注册表。
- 动态菜单加载远程页面时，按最新版规范配置 `moduleFederationRemoteNames`、`moduleFederationRemoteEntries`、环境变量和开发代理。
- 源码直接消费远程模块时，额外配置编译期 remote 与 TypeScript 声明。

## 实现要求

- 不根据历史技能示例猜测 `aura-core` 的 expose key；先检查当前 manifest、配置和类型。
- 远程页面不会执行提供方 `index.html` 与 `main.ts`，不能只依赖全局注册副作用。
- 远程 i18n、Tailwind 和页面 CSS 按最新版规范加载。
- Element Plus 保持本地依赖，不加入 Module Federation shared。
- import 静态资源经 `getStaticResourceUrl`；public 资源经 `getPublicResourceUrl`。
- 加载失败只影响当前内容区，并提供符合项目约定的重试能力。
