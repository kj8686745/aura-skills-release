# PIGX Nexus 项目画像

本文件只做快速导航，项目事实以当前源码、类型和 `../knowledge/PIGX前端开发规范/` 最新版正文为准。

## 当前基线

- Vue 3.5、TypeScript 5.9.3、`<script setup>`
- Vite 6.4.3、pnpm 10、Node.js >=22.12.0
- Element Plus 2.14.6
- Pinia 2、Vue Router 4、Vue I18n 9
- `@module-federation/vite@1.23.5`、`@module-federation/enhanced@2.9.2`
- SCSS、Tailwind CSS、主题 CSS 变量、远程 scoped Tailwind
- 项目内部别名：`/@/`

版本升级后以 `package.json`、锁文件和最新版总览为准，不固守本文件数字。

## 关键事实

- 业务请求统一走 `/@/config/aura/request`。
- 消息提示和弹框统一从 `/@/config/aura/index` 使用 `useMessage`、`useMessageBox`。
- 远程页面加载时不会执行提供方 `index.html` 和 `main.ts`。
- import 静态资源经 `getStaticResourceUrl`；public 资源经 `getPublicResourceUrl`。
- Element Plus 保持本地依赖，并在 Module Federation shared 中配置 singleton，requiredVersion 为 ^2.14.6。
- API、组件、Hook 和全局组件名称必须从当前项目真实源码确认。

## 开发前检查

1. 读取最新版规范 README、总览、工程规范和开发检查清单。
2. 检查 `package.json`、`vite.config.*`、web-kit exports、`src/config/aura/`、aura-ui 导出和相邻业务模块。
3. 选择正式页面模式。
4. 确认接口、权限、菜单、模块联邦、静态资源和独立/远程验收范围。
