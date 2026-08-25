# 页面模式适配配方

页面模式原始规范在 `knowledge/代码约束/页面模式/`。

## 使用方式

| 页面类型 | 先读知识库 | 当前项目适配 |
|----------|------------|--------------|
| 查询表格页 | `查询表格页.md` | 使用 `src/hooks/table.ts`；如缺 Pagination/RightToolbar，按内置封装标准补齐 |
| 查询卡片页 | `查询卡片页.md` | 使用当前项目卡片容器和 Element Plus CSS 变量 |
| 弹窗表单 | `弹窗表单.md` | 子组件异步引入，`defineExpose({ openDialog })`，使用 `useForm` |
| 左树右表 | `左树右表页.md` | 如需 QueryTree/Splitpanes，先确认依赖并按内置封装标准补齐 |
| 看板页 | `看板页.md` | 图表统一用 `useECharts`，交互必须 VueUse |
| 详情/抽屉 | `详情页与抽屉.md` | 抽屉组件异步引入，样式 scoped，避免全局高度污染 |

## 关键转换

- `/@/` → `@/`
- PIGX `layout-padding` → 当前项目页面内容容器，除非已补齐对应全局样式
- 后端菜单路由 → 当前 `src/router/index.ts` 本地路由
- 页面目录、页面文件、路由 path/name 必须按 `references/naming-conventions.md` 使用业务语义命名
- `v-auth`、`$t` → 先检查项目能力，不存在则不要生成
