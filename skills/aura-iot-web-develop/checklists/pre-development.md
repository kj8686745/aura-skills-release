# 开发前检查清单

## 需求定位

- [ ] 已检查 `templates/` 是否存在匹配预设模板；命中则按模板开发，未命中具体页面模板且没有可参考模板结构时，必须调用 `/frontend-design` 完成页面设计。

- [ ] 明确本次是页面、组件、接口、路由、状态、样式还是封装变更。
- [ ] 明确是否涉及 qiankun、Element Plus namespace、全局样式或请求封装。
- [ ] 如果超过 3 步或涉及多文件，先调用 `/planning-with-files-junmoxiao`。

## 资料读取

- [ ] 读取 `references/project-profile.md`。
- [ ] 读取 `references/naming-conventions.md`，并确定 API、页面、路由、组件、store、hooks、样式文件命名依据。
- [ ] 根据任务读取 `knowledge/代码约束/` 中相关页面模式或规范。
- [ ] 如涉及 Vue 组合式逻辑，调用 `/vueuse-functions`。
- [ ] 如新页面没有命中具体页面模板、没有可参考模板结构，调用 `/frontend-design` 完成页面设计。
- [ ] 如涉及 UI/UX 设计质量评审或用户明确要求体验优化，调用 `/ui-ux-pro-max`。
- [ ] 如涉及浏览器验证，必须调用 `/agent-browser`。

## 项目适配

- [ ] 将知识库中的 `/@/` 改为当前项目 `@/`。
- [ ] 不假设存在 `src/theme-core`、`src/router/route.ts`、全局 `v-auth`、完整 i18n。
- [ ] 检查是否需要按技能内置封装标准补齐封装。
- [ ] 检查当前项目是否已安装所需依赖；未安装依赖不得擅自安装，需用户授权。


## 页面拆分与复用判定

- [ ] 已根据真实需求判定是否需要弹窗、抽屉、详情、图表、复杂查询区等独立区块；有对应需求才拆对应组件，无对应需求不得创建无意义文件。
- [ ] 已判定局部区块是否模块内复用；有则必须放到页面模块 `components/` 或模块级组件目录。
- [ ] 已判定区块是否跨页面/跨模块复用；有则必须沉淀到 `src/components/`。
- [ ] 已判定样式是否跨页面复用；有则必须写入 `src/styles/page.scss`。
- [ ] 已判定页面私有样式是否过多；有则必须拆到页面模块 `styles/`。
- [ ] 已判定是否存在 VueUse 可替代手写逻辑；有则必须调用 `/vueuse-functions`。
