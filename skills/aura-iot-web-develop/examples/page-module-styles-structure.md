# 示例：页面模块样式拆分结构

当页面私有样式较多，且不适合放入全局 `src/styles/page.scss` 时，使用以下结构：

```text
src/views/device/monitor/
├── index.vue
├── components/
│   ├── SearchPanel.vue
│   └── TrendChart.vue
└── styles/
    ├── index.scss
    ├── search.scss
    └── chart.scss
```

`index.vue`：

```vue
<style scoped lang="scss">
@use './styles/index.scss';
</style>
```

`styles/index.scss`：

```scss
@use './search.scss';
@use './chart.scss';

.monitor-page {
  color: var(--el-text-color-primary);
}
```

要求：

- 页面私有样式必须用页面根类包裹。
- 颜色必须使用 Element Plus CSS 变量。
- 能用 Tailwind 的布局和间距仍然写在模板 class 中。
```
