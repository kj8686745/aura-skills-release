# VueUse 选型配方

当前项目已安装 `@vueuse/core`，并已安装 `/vueuse-functions` 技能。

## 使用流程

1. 识别需求是否属于通用组合式逻辑。
2. 如果是，先调用 `/vueuse-functions` 或查询本配方映射。
3. 确认函数属于 `@vueuse/core`，无需额外依赖。
4. 如函数属于 integrations/external，先确认依赖；未安装时请求用户授权。
5. 在交付说明中写明使用的 VueUse 函数。

## 常用映射

| 需求 | 函数 |
|------|------|
| 搜索防抖 | `watchDebounced`、`useDebounceFn` |
| 按钮节流 | `useThrottleFn` |
| 本地持久化 | `useLocalStorage`、`useStorage` |
| 弹窗外点击 | `onClickOutside` |
| 元素尺寸 | `useResizeObserver`、`useElementSize` |
| 窗口尺寸 | `useWindowSize` |
| 复制文本 | `useClipboard` |
| 全屏 | `useFullscreen` |
| 网络状态 | `useOnline`、`useNetwork` |
| 页面可见性 | `useDocumentVisibility` |
| 定时轮询 | `useTimeoutPoll`、`useIntervalFn` |
| 倒计时 | `useCountdown` |
| 布尔切换 | `useToggle` |
| 异步状态 | `useAsyncState` |
| 虚拟列表 | `useVirtualList` |

## 与项目封装边界

- 表格分页不要用 VueUse 替代 `useTable`。
- 图表生命周期不要绕过 `useECharts`，但 `useECharts` 内可使用 `useResizeObserver`。
- 服务式 MessageBox 不用 VueUse 替代 `useMessageBox`。
- 表单重置必须 `useForm`，复杂输入交互再叠加 VueUse。
