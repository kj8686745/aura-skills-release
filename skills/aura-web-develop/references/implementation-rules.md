# 业务实现约束

修改 Vue/TypeScript 业务代码、命名、组件结构或布局时读取；专项数据与时间规则分别见技能入口对应索引。

## 命名强制约束

- 项目、目录、Vue/CSS/SCSS/HTML 和静态资源文件使用小写 `kebab-case`；JavaScript/TypeScript 模块文件使用 `camelCase`，例如 `mapConfig.ts`、`coordinateTransform.ts`。
- 组合式 Hook 文件使用 `useXxx.ts`，导出函数使用 `useXxx`；Vue 组件名使用 PascalCase，组件文件仍使用 `kebab-case`。
- 函数、方法、变量、参数和对象成员使用 lowerCamelCase；常量使用 UPPER_SNAKE_CASE；类型、接口、枚举和类使用 PascalCase。
- CSS/SCSS 类名使用小写 `kebab-case`，组件样式优先采用 BEM（`block__element--modifier`）；避免标签、ID 和全局通配符选择器。
- 函数名必须包含动作和业务对象语义，禁止使用 `save`、`query`、`data1`、`useData` 等无法表达职责的过泛名称。
- 新增命名必须使用正确英文单词，禁止拼音、中文、无意义缩写和大小写混用；已有文件不因本规则批量重命名。

## 组件、状态与布局

- 使用 Vue 3、TypeScript 和 `<script setup>`，具体版本以当前项目和最新版总览为准。
- 路由页必须保持单一真实元素根节点；根元素统一使用 `class="layout-padding"`，业务区域置于 `class="layout-padding-auto layout-padding-view"`，Dialog、Drawer 等弹窗可与业务区域并列置于根节点下，以兼容框架的 Transition 和运行时指令。
- 业务路由入口保留在业务目录的 `index.vue`。凡由该页面引入的私有页面组件，包括表单、详情、弹窗、抽屉、面板和嵌套业务视图，必须放入同路径的 `components/` 目录，禁止与 `index.vue` 并列；确需跨业务复用时才放入 `src/components`。
- 同一路由页出现两个及以上业务 Dialog/Drawer，或单个弹窗同时包含独立列表、表单、请求与提交状态时，编码前必须拆为页面私有组件；父页通过 `ref + defineExpose` 或 Props/Emits 编排。只有字段少、无独立请求、无复用价值的单一轻量弹窗可以内联，并在职责清单中记录理由。
- 仅供弹窗使用的详情、候选项、字典项和业务列表由弹窗持有，并在公开的 `openDialog/openDrawer/open` 流程中按需加载；禁止父页面、弹窗挂载阶段或 `immediate` 监听提前请求。父页面只传入记录 ID、已选 ID 等本次操作上下文；只读加载失败使用弹窗局部错误态和重试，不弹全局消息。
- 顶部或摘要工具栏已有新增等主操作时，空态不得重复放置相同按钮；只保留说明、重试、授权或当前状态独有的恢复操作。
- 父子组件自定义事件及任何需要访问组件 ref 的模板事件必须绑定脚本中已定义的具名方法，例如 `@edit="handleEdit"`；禁止直接绑定或调用组件 ref 成员，也禁止用内联箭头函数访问 ref。普通业务方法可按需接收当前行等上下文；需要调用子组件公开方法时，由具名方法通过 `ref.value?.method(...)` 安全访问，避免挂载前在渲染阶段读取 `undefined`。
- 模板使用全局或局部组件时，`<script setup>` 中的 `ref/reactive/computed/shallowRef/shallowReactive` 数据绑定不得与任何组件标签同名或规范化后同名，否则 Vue 会把响应式数据当作组件解析。数据状态统一使用带业务语义的 `xxxState`、`xxxData` 或放入所属 `state.xxx`；交付前必须运行项目规则扫描检查此类遮蔽。
- 项目内部路径使用 `/@/`，避免跨层级相对路径。
- 列表页按真实 `useTable(state)` 签名传入响应式状态，并使用返回的 `tableStyle`、分页、排序和下载能力；不要从返回值中解构不存在的 `state`。
- 常规 CRUD 明确要求表格占满剩余高度时，页面容器建立纵向 Flex 高度链路，滚动父级和表格区写 `min-height: 0`，表格使用 `class="el-table--fit"` 与 `flex: 1`；不得使用 `100vh` 或固定像素表格高度。
- 普通内容区域需要滚动时必须使用 Element Plus `el-scrollbar`，不得用 `overflow: auto/scroll`、`overflow-y-auto`、`overflow-auto` 等原生 CSS/Tailwind 滚动实现；查询区、工具栏和分页置于滚动区域外。`el-table`、`el-tree`、`el-select` 等已有内置滚动能力的 Element Plus 组件优先使用其公开高度、最大高度或组件自身滚动能力，不额外套 `el-scrollbar`。
- v-loading 覆盖的区域如果自身或实际滚动容器可能滚动，loading 期间必须锁定该滚动容器（overflow: hidden 或等效状态类），loading 结束后恢复；局部表格、树、弹窗和地图只锁定其实际覆盖区域，不得误锁整页。
- 新建或修改普通 `el-select` 默认添加 `filterable`；仅用户明确关闭、组件不兼容或需求明确禁止搜索时例外，并说明原因。
- 权限按钮遵循项目 `v-auth` 约定；只承载受限操作的上层容器必须按全部子操作权限的并集控制可见性，例如表格操作列使用 `v-if="permissions.any([...])"`，同时保留各按钮自己的 `v-auth`。卡片操作区、仅含受限按钮的工具栏分组、下拉触发器和批量选择列同理，禁止在所有子操作均无权限时留下空列、空菜单、空白 footer、分隔线或占位间距；包含查看、刷新等无权限操作的混合容器不得整体隐藏，只隐藏其中受限分组。表单提交前校验，提交期间禁用，成功后再关闭和刷新。
- 所有业务表单必须从 `/@/hooks/form` 使用 `useForm`；通过 `validateForm` 校验，通过 `resetForm` 重置字段，通过 `clearFormValidate` 清理复用弹窗的历史校验状态。业务页面禁止直接调用表单实例的 `validate/resetFields/clearValidate`，也不得重复编写对应逻辑。
- import 图片、SVG、视频等先经 `getStaticResourceUrl`；Worker、decoder 等 public 资源经 `getPublicResourceUrl`。
- 业务开发需要颜色时，按 `--el-*` → `--next-*` → `--fxft-*` 的顺序从现有主题变量中选用；变量含义和场景以 `knowledge/PIGX前端开发规范/样式布局与静态资源规范.md` 为准。
- 除非用户明确要求，业务开发不得新增或修改 `.el-*`、`:deep(.el-*)`、`--el-*` 重写及全局 Element Plus 样式覆盖；正常使用 Element Plus 组件公开 props 不受影响。
- 不直接创建 axios 实例，不自行处理认证失效，不硬编码域名、IP、Token、Cookie、密码或部署前缀。
- Element Plus 保持本地依赖，不加入 Module Federation shared；Vue、Vue Router、Vue I18n、Pinia 按最新版模块联邦规范共享。
- 地图使用 `FxftMap`；单路和多路视频使用 `FxftVideoPlayer`、`FxftMultiVideoPlayer`，不得重复封装底层 SDK。
- 中文文档、注释、提示和新增文本文件使用 UTF-8 无 BOM。
