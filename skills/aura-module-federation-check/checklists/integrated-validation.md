# AURA 综合端模块联邦验收清单

## 静态审计

- [ ] 只按 1.2.0 公共包绑定验收；不保留旧运行时文件与旧 alias 兼容。
- [ ] 当前项目声明与所属锁文件的依赖条目一致，解析版本满足声明并与实际安装版本一致，实装达到 `>=1.13.1`。已核验使用入口的 exports、类型与实现。缺证列为未证实。
- [ ] 1.2.0 Node ≥22.12.0、Element Plus 2.14.6 singleton；auraAutoOptimizeDeps、共享 AutoImport 预设与 resolver 工厂、公共构建插件与 PostCSS 已接入。
- [ ] 多级 remoteEntryName 与完整部署前缀一致，index.html 与 main.ts 启动缓存均按 remoteName。

- [ ] 脚本识别结果为 `Integrated`。
- [ ] 逐项核实脚本定位的源码、最终配置与产物，记录有效偏差、静态误报的依据及待补证项。
- [ ] 模板占位身份已全部替换。
- [ ] shared singleton、运行时外壳、i18n 和样式扩展口完整。
- [ ] 业务 expose key、目标文件、i18n 扫描目录和 manifest 一致。
- [ ] 运行时远程、环境变量、开发代理、编译期 remotes 和类型声明一致。
- [ ] 远程 Vue 模板组件使用 `defineAsyncComponent` 动态导入。
- [ ] 后台菜单 `componentPath` 已通过脚本检查，且“带参”已开启。
- [ ] 改动前留有检查结果；修复后已复检，并记录已解决、待决策和仍待验证的事项。

## 构建验证

- [ ] 已对照公共预构建入口登记核对实际使用、resolver 输出和最终 include；未使用的入口不强制添加，根包 include 不代替子入口检查。
- [ ] 首次进入相关菜单已用冷启动 dev 验证，记录新增优化日志与整页导航证据；静态命中或生产 build 不等于此项通过。
- [ ] 新确认的公共预构建入口已补录包版本、适用条件、精确路径与证据。

- [ ] 使用项目声明的 Node 和 pnpm 版本。
- [ ] 依赖已存在时执行 `pnpm build`；不为只读审计擅自安装或升级依赖。
- [ ] `dist/remoteEntry.js` 和 `dist/mf-manifest.json` 存在。
- [ ] manifest 包含 runtime、i18n 和 scoped Tailwind 标准 expose。
- [ ] 核对模板静态属性、CSS `url()`、脚本导入与提供方生效的 Vite 资源回调和构建产物。外链 CSS 中的打包资源相对样式表解析，qiankun 内联 CSS 按部署前缀解析。旧项目按实际配置与资源结果核对兼容处理。
- [ ] 接入默认资源回调后，核对 public 产物的相对地址、提供方部署的文件位置及代理可达性。固定 public 资源通过 `?url` 导入或编译 CSS `url()` 获取地址，Vue `:style` 绑定导入值。普通行内样式、SDK 普通路径及其他运行时拼接路径按 `getPublicResourceUrl` 核对。qiankun 内联 CSS 使用 `cssUrlMode: 'base'`，HTML 与 SSR 依 Vite 原路径规则处理。
- [ ] 联调 `vite preview` 时确认预览服务读取的目录已用当前配置重建。

## 运行时验证

- [ ] 项目可独立运行并正常登录、切换路由。
- [ ] 作为远程页面加载时内容、i18n、Element Plus 文案和样式正常。
- [ ] 图片、字体、视频和 Worker 请求指向正确的远程资源根路径。图片响应返回实际图片内容，核对响应类型或解码结果。
- [ ] 远程加载失败只影响当前内容区，其他菜单仍可访问。
- [ ] “重新加载”能刷新远程容器、manifest、i18n 和样式缓存。

## 人工确认

- [ ] `remoteName`、`remoteEntryName`、`systemId` 在部署环境中唯一。
- [ ] `VITE_PUBLIC_PATH` 与 Nginx 实际部署前缀一致。
- [ ] 独立生产端或消费端项目未误用本技能的综合端通过结论。
- [ ] 提供方交付时已列出 `remoteName`、`remoteEntryName`、待填 manifest 环境变量、业务/i18n/样式 expose、远程菜单 `componentPath` 与“带参”要求；未确认地址未被猜测。
- [ ] 给定明确消费方项目时，运行时入口、环境变量和开发代理按真实现有结构接入；只有源码直接引入才增加编译期 remote、TypeScript 声明和异步组件边界。

- [ ] TypeScript 5.9.3、ESLint 8.57.1、typescript-eslint parser/plugin 8.46.1 配套；Vue parser 分层、专用 tsconfig.vite.json、定向 tsc/lint/print-config 和构建分别留证，不宣称全量业务类型通过。
- [ ] 自动发现报告与最终 optimizeDeps 覆盖实际入口，无旧扫描插件；独立 dev 与实际宿主冷启动首次菜单及往返分别留证。
