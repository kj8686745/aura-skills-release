# 开发前检查清单

在开始任何 2D 地图业务开发前，逐项确认。

## 需求确认

- [ ] 已确认需求属于 2D 地图业务。
- [ ] 已识别业务场景：基础地图 / 点位聚合 / 轨迹回放 / 热力图 / 绘制 / GeoJSON。
- [ ] 已确认是否需要真实接口数据。
- [ ] 已确认地图容器所在页面或路由。
- [ ] 点位场景已确认唯一业务主键、分类显隐语义和聚合数量口径。
- [ ] 已确认聚合半径需要视觉像素语义还是固定实际距离语义。

## 依赖检查

- [ ] 已读取目标项目 `package.json`。
- [ ] 已确认是否安装 `@fxft/ui-plus`。
- [ ] 如果未安装，已向用户说明并等待授权。
- [ ] 已确认目标项目包管理器，不混用 npm、pnpm、yarn。

## 接入检查

- [ ] 已检查 `vite.config.ts`。
- [ ] 已确认是否配置 `unplugin-vue-components`。
- [ ] 已确认是否配置 `unplugin-auto-import`。
- [ ] 已确认是否配置 `FxftUiPlusResolver`。
- [ ] 已确认目标项目是否已有全量注册 `FxftUiPlus`。

## 资料读取

- [ ] 已读取 `references/project-profile.md`。
- [ ] 已读取 `references/map-business-rules.md`。
- [ ] 已读取命中的地图模板。
- [ ] 涉及安装时已读取 `references/ui-plus-installation.md` 和 `recipes/install-and-resolver.md`。
- [ ] 涉及坐标、轨迹、热力时已读取 `recipes/map-data-normalization.md`。
