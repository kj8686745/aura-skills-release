# 实现检查清单

## 命名

- [ ] 新增 API、页面、路由、组件、store、hooks、样式文件已按 `references/naming-conventions.md` 使用业务语义命名。
- [ ] API 文件名体现业务域和业务对象，没有使用 `api.ts`、`online.ts`、`common.ts` 等过泛命名。
- [ ] 页面目录/文件名体现页面业务用途，没有使用 `Page.vue`、`Report.vue`、`DownloadView.vue` 等弱语义命名。
- [ ] 路由 path/name/meta.title 与页面业务一致。
- [ ] 组件、store、hooks 名称体现职责和业务对象，没有使用 `MyComponent`、`useData`、`usePageStore` 等命名。

## Vue 与 TypeScript

- [ ] 新增 `.vue` 使用 `<script setup lang="ts">`。
- [ ] 不手动 import 已由 AutoImport 提供的 `ref`、`reactive`、`computed`、`watch`、`onMounted`、`useRoute`、`useRouter` 等。
- [ ] 项目内部路径使用 `@/`。
- [ ] 类型定义尽量明确，避免把接口响应整体设为 `any`。

## 分层

- [ ] 页面放在 `src/views/`。
- [ ] 请求封装放在 `src/api/`，页面不直接调用 axios。
- [ ] 复杂页面已按实际场景拆分：主页面保留编排逻辑；弹窗才拆 `form.vue`；详情才拆 `detail.vue`/`drawer.vue`；可复用区块才放局部 `components/`。
- [ ] 跨页面共享状态才进入 `src/stores/`。

## 项目封装

- [ ] 查询表格必须使用 `src/hooks/table.ts` 的 `useTable`。
- [ ] 图表开发必须使用 `src/hooks/echarts.ts` 的 `useECharts`。
- [ ] 消息和确认框必须使用 `src/hooks/message.ts`，保证服务式 MessageBox 继承 `aura` namespace。
- [ ] 表单重置必须使用 `src/hooks/form.ts`。
- [ ] 当前项目缺失的公共组件或 hooks，必须按技能内置封装配方补齐并适配。

## VueUse

- [ ] 检查是否可用 VueUse 替代手写逻辑。
- [ ] 防抖节流必须使用 `useDebounceFn`、`watchDebounced`、`useThrottleFn`。
- [ ] DOM 监听必须使用 `useEventListener`、`useResizeObserver`、`useElementSize`。
- [ ] 存储必须使用 `useLocalStorage`、`useSessionStorage`、`useStorage`。
- [ ] 定时器和轮询必须使用 `useIntervalFn`、`useTimeoutPoll`。

## 样式隔离

- [ ] 不移除 `.foundation-dev-web`。
- [ ] 不移除 `aura` namespace。
- [ ] 新样式默认 `<style scoped>`。
- [ ] 不新增全局 `.el-*` 覆盖。
- [ ] 颜色/边框/背景必须使用 Element Plus CSS 变量。


## 组件拆分

- [ ] 单页面代码体量已检查，复杂页面不把所有内容堆在 `index.vue`。
- [ ] 弹窗、抽屉、详情、图表卡片、复杂查询区已按职责拆成局部组件。
- [ ] 当前模块局部组件放在 `src/views/<module>/<page>/components/`。
- [ ] 有跨页面复用场景的组件已抽到 `src/components/`。
- [ ] 公共组件不耦合具体接口、权限码和页面状态。

## 样式复用

- [ ] 多页面复用的页面容器、工具栏、卡片、图表容器样式写入 `src/styles/page.scss`。
- [ ] 页面模块私有样式较多时，已拆到 `src/views/<module>/<page>/styles/`。
- [ ] 只属于当前组件的样式保留在 `<style scoped>`。
- [ ] 没有在多个页面重复复制同一段公共样式。
- [ ] 公共样式使用 CSS 变量，不写死主题色。


## CSS 与 Tailwind

- [ ] 能用 Tailwind 表达的布局、间距、尺寸、圆角、文字、响应式样式，已使用 Tailwind。
- [ ] Tailwind 无法清晰表达的复杂选择器、穿透、动画或页面模块私有样式，才写 SCSS。
- [ ] Tailwind 颜色类必须绑定 Element Plus 主题变量；未配置语义色时使用 `text-[var(--el-text-color-primary)]` 这类任意值写法。
- [ ] SCSS 中颜色、背景、边框、阴影必须使用 Element Plus CSS 变量。
- [ ] 未出现 `#fff`、`#333`、`#ebeef5`、固定 rgb/rgba 主题色等硬编码颜色。
- [ ] 涉及样式时已查看 `references/css-tailwind-guidelines.md` 和 `examples/`。
