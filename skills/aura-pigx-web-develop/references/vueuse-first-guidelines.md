# VueUse 优先规范

## 总原则

- Vue 组合式逻辑必须先调用 `/vueuse-functions` 做函数选型。
- `@vueuse/core` 已能覆盖的能力，优先使用 VueUse，减少手写状态、监听、定时器和生命周期清理代码。
- 不为了使用 VueUse 绕开项目封装：表格、表单、消息、字典、参数仍优先使用 `useTable`、`useForm`、`useMessage`、`useDict`、`useParam`。
- 禁止使用会绕过项目请求封装的 VueUse 能力，例如 `useFetch`、`useAxios`；接口请求必须走 `/@/utils/request.ts` 和业务 API 模块。
- 若 VueUse 对应函数属于外部依赖或当前项目未安装的集成包，不能静默安装，先评估是否可用 `@vueuse/core` 或项目内封装替代。

## 必须优先用 VueUse 的场景

| 场景 | 优先函数 |
|---|---|
| 事件监听、键盘事件、点击外部区域 | `useEventListener`、`onKeyStroke`、`onClickOutside` |
| 防抖、节流、输入联动 | `useDebounceFn`、`useThrottleFn`、`refDebounced`、`watchDebounced`、`watchThrottled` |
| DOM 尺寸、可见性、滚动、窗口尺寸 | `useElementSize`、`useElementVisibility`、`useResizeObserver`、`useScroll`、`useWindowSize` |
| 定时器、轮询、倒计时 | `useIntervalFn`、`useTimeoutFn`、`useTimeoutPoll`、`useCountdown` |
| 本地存储、会话存储 | `useLocalStorage`、`useSessionStorage`、`useStorage` |
| 布尔状态切换、计数、步骤流 | `useToggle`、`useCounter`、`useStepper` |
| 异步状态、一次性等待、条件触发 | `useAsyncState`、`until`、`whenever` |
| 复制、全屏、文件选择、对象 URL | `useClipboard`、`useFullscreen`、`useFileDialog`、`useObjectUrl` |
| WebSocket、EventSource | `useWebSocket`、`useEventSource` |
| 动效和无障碍媒体偏好 | `useTransition`、`usePreferredReducedMotion` |

## 禁止手写的常见代码

- 手写 `window.addEventListener` / `removeEventListener` 配对逻辑，除非 VueUse 无法覆盖。
- 手写 `setInterval` / `setTimeout` 且缺少卸载清理。
- 手写 `ResizeObserver` / `IntersectionObserver` / `MutationObserver` 生命周期管理。
- 手写防抖节流工具函数。
- 手写 `localStorage` / `sessionStorage` 与响应式状态同步。

## 允许不用 VueUse 的情况

- 项目已有更高优先级封装，例如 `useTable`、`useForm`、`useMessage`、`useDict`、`useParam`、`useECharts`。
- VueUse 函数会引入额外未安装依赖，且项目内已有稳定替代方案。
- 简单 `computed`、`ref`、`watch` 更直观，使用 VueUse 反而增加理解成本。
- 第三方组件 SDK 要求直接使用原生实例或回调。

## 交付说明

交付时必须说明使用了哪些 VueUse 函数；如果涉及事件监听、定时器、DOM 观测、防抖节流、存储同步等场景但未使用 VueUse，需要说明原因。
