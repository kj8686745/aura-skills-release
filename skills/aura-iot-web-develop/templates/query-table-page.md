# 模板：查询表格页

## 适用场景

- 有查询条件、表格列表、分页。
- 可包含新增、编辑、删除、导出等操作。
- 是否拆分查询区、工具栏、表格列渲染，必须看需求复杂度。

## 强制规则

- 必须使用 `src/hooks/table.ts` 的 `useTable`。
- 必须通过 `src/api/` 调用接口。
- 表格样式必须使用 `useTable` 返回的 `tableStyle`。
- 如果需要分页组件但当前项目没有公共组件，必须按技能封装标准补齐或在页面内实现临时明确结构。
- 复杂查询区才拆 `SearchPanel.vue`；简单查询留在 `index.vue`。
- 有新增/编辑弹窗需求才创建 `form.vue`。
- 有详情需求才创建 `detail.vue` 或 `drawer.vue`。

## 推荐结构

```text
src/views/<module>/<page>/
├── index.vue
├── form.vue                 # 可选：仅新增/编辑弹窗需要
├── detail.vue / drawer.vue  # 可选：仅详情/抽屉需要
├── components/              # 可选：仅复杂局部区块需要
└── styles/                  # 可选：仅页面私有样式较多时需要
```
