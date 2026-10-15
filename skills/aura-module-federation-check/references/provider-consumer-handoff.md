# 提供方对外接入与消费方接入

仅在 PIGX 综合端修改完成、复检没有 `error` 级确定错误后读取本参考。交付提供方时，基于当前项目真实配置输出下列信息：

- `remoteName` 与 `remoteEntryName`；
- 指向 `mf-manifest.json` 的待填环境变量名称；未确认部署地址时只保留变量占位，不猜测 URL 或发布路径；
- 业务页面、组件、API 等真实 expose key；
- 标准 i18n expose `./i18n/langs` 与样式 expose `./styles/moduleFederationTailwind.ts`；
- 每个远程菜单的完整 `componentPath`：`/{remoteName}/{expose key 去掉开头点}?type=moduleFederation`，并明确管理端必须开启“带参”。

## 给定明确消费方项目时

用户明确提供消费方项目并要求接入后，直接读取该项目现有模块联邦配置、环境变量和开发代理，再按真实命名与文件结构修改：

1. 将提供方 `remoteName` 加入运行时远程名称；
2. 在运行时入口映射中使用对应的 manifest 环境变量；
3. 补齐目标环境文件中的变量占位或用户提供的部署地址；
4. 开发联调需要时按提供方 `remoteEntryName` 和现有代理风格新增开发代理；
5. 动态菜单只配置运行时入口和完整 `componentPath`，不得因此新增 Vite 编译期 remote。

只有消费方源码直接 import 远程模块时，才额外修改编译期 remote 映射、TypeScript 模块声明，并为直接渲染的远程 Vue 组件使用 `defineAsyncComponent` 异步边界。远程 API、类型和工具按其实际导入形式处理，不把页面菜单加载误判为源码直接引入。

## 不能确认的信息

不能确认 manifest 部署地址、目标环境、消费方项目或写入授权时，只交付待填的环境变量、真实 expose 与菜单配置说明；不得伪造地址、修改未指定项目或把动态菜单误配成编译期 remote。
