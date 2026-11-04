# 样式与 Tailwind 补充说明

正式规则以 `../knowledge/PIGX前端开发规范/样式布局与静态资源规范.md` 和当前项目配置为准。

- 项目支持 SCSS、Tailwind CSS、主题 CSS 变量和远程 scoped Tailwind；不要把 Tailwind 或 SCSS 绝对化为唯一方案。
- 使用当前项目已有的布局工具类和页面模式，保持 Flex 高度链路、`min-height: 0` 与滚动容器正确。
- 颜色、边框和交互态优先使用 Element Plus/综合端主题变量，避免大面积硬编码主题色。
- 远程 Tailwind scope 必须与当前 `remoteName` 一致，宿主不扫描远程源码生成 Tailwind。
- 禁止无 scope 重置 `body`、`html` 或全局 `.el-*`。
- import 静态资源使用 `getStaticResourceUrl`，public 根路径资源使用 `getPublicResourceUrl`。
- `:deep()`、`!important`、复杂布局补丁和第三方覆盖应添加简体中文 Why 注释。
- 具体写法以当前项目 Tailwind/PostCSS/SCSS 配置和最新版页面模式为准。
