# 模板：看板图表卡片

## 适用场景

- 指标卡片、趋势图、分布图、排名图、看板页面。

## 强制规则

- 图表必须使用 `src/hooks/echarts.ts` 的 `useECharts`。
- 图表容器尺寸监听必须使用 VueUse，例如 `useResizeObserver` 或 `useElementSize`。
- 图表卡片如果超过一个或可复用，必须拆成局部组件。
- 跨页面复用的图表卡片必须沉淀到 `src/components/`。
- 看板公共样式必须放入 `src/styles/page.scss`；页面私有样式较多时放入页面模块 `styles/`。
