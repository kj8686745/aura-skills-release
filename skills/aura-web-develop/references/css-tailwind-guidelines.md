# 样式与 Tailwind 补充说明

正式规则以 `../knowledge/AURA前端开发规范/样式布局与静态资源规范.md` 和当前项目配置为准。

- 项目支持 SCSS、Tailwind CSS、主题 CSS 变量和远程 scoped Tailwind；不要把 Tailwind 或 SCSS 绝对化为唯一方案。
- 使用当前项目已有的布局工具类和页面模式，保持 Flex 高度链路、`min-height: 0` 与滚动容器正确。
- 颜色、边框和交互态优先使用 Element Plus/综合端主题变量，避免大面积硬编码主题色。
- 远程 Tailwind scope 必须与当前 `remoteName` 一致，宿主不扫描远程源码生成 Tailwind。
- 禁止无 scope 重置 `body`、`html` 或全局 `.el-*`。
- 项目接入联邦资源回调后，由 Vite 编译的 CSS `url()` 使用源码别名或相对样式文件的路径，运行时动态背景使用 JS 静态导入值，Vite 识别的 public URL 默认随外链样式表定位，qiankun 内联 CSS 随部署前缀定位，运行时计算的 public 路径使用 `getPublicResourceUrl`。见[public 资源用法](../knowledge/AURA前端开发规范/样式布局与静态资源规范.md#七public-资源)。
- `:deep()`、`!important`、复杂布局补丁和第三方覆盖应添加简体中文 Why 注释。
- 具体写法以当前项目 Tailwind/PostCSS/SCSS 配置和最新版页面模式为准。
