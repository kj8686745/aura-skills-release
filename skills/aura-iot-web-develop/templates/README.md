# 预设模板索引

开发新页面或新模块时，必须先检查本目录是否存在匹配模板。

## 使用顺序

1. 根据用户需求判断页面类型。
2. 先在本目录查找匹配模板。
3. 如果存在模板：按模板结构生成，并结合 `knowledge/`、`references/`、`checklists/` 做当前项目适配。
4. 如果不存在匹配的具体页面模板、没有可参考模板结构：先调用 `/frontend-design` 完成页面设计，再结合命名规范、组件拆分规范、样式复用规范和 VueUse 规则实现。
5. 生成任何文件前，必须读取 `references/naming-conventions.md` 并按业务语义命名。
6. 交付时说明：本次命中的模板；如果未命中，说明调用了 `/frontend-design` 和哪些规范自行设计。

## 当前预设模板

| 模板 | 适用场景 |
|------|----------|
| `query-table-page.md` | 查询条件 + 表格 + 分页 + 可选操作按钮 |
| `dialog-form.md` | 新增/编辑弹窗表单 |
| `dashboard-chart-card.md` | 看板/图表卡片 |
| `api-module.md` | API 接口封装、类型定义、请求函数导出 |
| `pinia-store.md` | Pinia 全局状态、用户上下文、跨页面状态 |
| `components/README.md` | 公共组件模板索引，按展示、双向绑定、插槽、表单项、弹窗、列表卡片分场景 |

## templates 与 examples 分工

- `templates/` 放可复制的最小生成骨架和强约束。
- `examples/` 放完整示例、风格参考和组合实践。
- 详细边界见 `references/template-vs-example-guidelines.md`。

## 不允许

- 不允许不看模板就直接生成页面。
- 不允许没有新增/编辑需求却强行创建 `form.vue`。
- 不允许没有详情/抽屉需求却强行创建 `detail.vue` 或 `drawer.vue`。
- 不允许模板未覆盖时硬套模板；模板不匹配时必须调用 `/frontend-design` 完成页面设计，再按需求和规范实现。
