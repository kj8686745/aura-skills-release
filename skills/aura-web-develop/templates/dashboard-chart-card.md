# 看板与图表模板入口

完整读取：

- `../knowledge/PIGX前端开发规范/页面模式/看板页.md`
- `../knowledge/PIGX前端开发规范/样式布局与静态资源规范.md`
- 当前项目 `src/config/aura/echarts.ts` 与 `@fxft/aura-web-kit/hooks/echarts` 的公开声明

以真实 `useECharts` 公开 API 为准处理 option、空态和容器 resize，不复制历史 ECharts Hook 签名。
