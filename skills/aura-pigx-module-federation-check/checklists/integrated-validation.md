# PIGX 综合端模块联邦验收清单

## 静态审计

- [ ] 脚本识别结果为 `Integrated`。
- [ ] 没有 `error` 级结果。
- [ ] 模板占位身份已全部替换。
- [ ] shared singleton、运行时外壳、i18n 和样式扩展口完整。
- [ ] 业务 expose key、目标文件、i18n 扫描目录和 manifest 一致。
- [ ] 运行时远程、环境变量、开发代理、编译期 remotes 和类型声明一致。
- [ ] 远程 Vue 模板组件使用 `defineAsyncComponent` 动态导入。
- [ ] 后台菜单 `componentPath` 已通过脚本检查，且“带参”已开启。
- [ ] 模块联邦配置改动前已保存检查基线，改动后已复检且没有 `error` 级确定错误。
- [ ] 每条 `warning` 已确认保留理由或完成修复。

## 构建验证

- [ ] 使用项目声明的 Node 和 pnpm 版本。
- [ ] 依赖已存在时执行 `pnpm build`；不为只读审计擅自安装或升级依赖。
- [ ] `dist/remoteEntry.js` 和 `dist/mf-manifest.json` 存在。
- [ ] manifest 包含 runtime、i18n 和 scoped Tailwind 标准 expose。

## 运行时验证

- [ ] 项目可独立运行并正常登录、切换路由。
- [ ] 作为远程页面加载时内容、i18n、Element Plus 文案和样式正常。
- [ ] 图片、字体、视频和 Worker 请求指向正确的远程资源根路径。
- [ ] 远程加载失败只影响当前内容区，其他菜单仍可访问。
- [ ] “重新加载”能刷新远程容器、manifest、i18n 和样式缓存。

## 人工确认

- [ ] `remoteName`、`remoteEntryName`、`systemId` 在部署环境中唯一。
- [ ] `VITE_PUBLIC_PATH` 与 Nginx 实际部署前缀一致。
- [ ] 独立生产端或消费端项目未误用本技能的综合端通过结论。
- [ ] 提供方交付时已列出 `remoteName`、`remoteEntryName`、待填 manifest 环境变量、业务/i18n/样式 expose、远程菜单 `componentPath` 与“带参”要求；未确认地址未被猜测。
- [ ] 给定明确消费方项目时，运行时入口、环境变量和开发代理按真实现有结构接入；只有源码直接引入才增加编译期 remote、TypeScript 声明和异步组件边界。
