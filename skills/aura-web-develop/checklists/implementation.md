# 实现检查清单

## 工程与职责

- [ ] 本次调用的外部技能均已确认安装；缺失项没有被假称已调用
- [ ] 技能安装仅在用户明确授权后执行；拒绝或安装失败时已按可降级/必需边界处理
- [ ] 页面实现完成后已明确说明使用 Codex 内置浏览器自查，未用外部 Chrome、`agent-browser` 或仅看源码代替
- [ ] 页面、页面私有组件、Composable、API、类型和 i18n 职责分离
- [ ] 路由页只保留布局、查询主状态和子组件编排；两个及以上业务 Dialog/Drawer 已拆为页面私有组件，复杂单弹窗也未内联堆积列表、表单和请求状态
- [ ] 仅供弹窗使用的详情、候选项和业务列表由弹窗持有，并在公开 `open` 流程中加载；父页面、组件挂载阶段和 `immediate` 监听未提前请求
- [ ] 父页面只传记录 ID、已选 ID 等操作上下文；保存后只刷新仍打开且确有需要的关联弹窗
- [ ] 文件与变量有业务语义，目录和命名符合最新版工程规范及相邻模块
- [ ] 项目内部 import 使用 `/@/`，没有错误的 `@/`
- [ ] 只修改需求范围内文件，不覆盖已有业务代码

## 请求与接口

- [ ] 请求统一使用 `/@/utils/request`，未直接创建 axios 实例
- [ ] API 命名遵循当前业务域与最新版规范，未强制旧版五段式
- [ ] 字段名、类型、必填性和单值/数组结构与明确接口契约一致
- [ ] 未硬编码域名、IP、Token、Cookie、密码或部署前缀
- [ ] 未在业务代码中自行处理认证失效、清 Token 或跳转登录

## Hooks、表格与表单

- [ ] `useTable(state)` 传入响应式状态，未从返回值解构不存在的 `state`
- [ ] 表格绑定 `tableStyle.cellStyle`、`tableStyle.headerCellStyle`
- [ ] 表格需要撑满剩余高度时，表格区通过纵向 Flex 与 `min-height: 0` 参与高度链路，`el-table` 同时使用 `class="el-table--fit"` 和 `flex: 1`，未使用 `100vh` 或固定像素高度
- [ ] 分页、排序、下载和对齐复用真实 `useTable` 能力
- [ ] 新增或修改的普通 `el-select` 默认使用 `filterable`；明确关闭或组件不兼容时有原因说明
- [ ] 权限按钮使用当前项目 `v-auth` 约定
- [ ] 正式新业务页面、菜单入口或操作按钮已生成菜单/按钮权限清单；多个相同 `v-auth` 已按唯一编码合并为一条后台按钮权限，并保留全部引用位置
- [ ] 用户指定的权限编码未被改写；未指定编码由真实“业务标识 + 功能动作”组成并遵循当前项目格式，页面 `v-auth` 与后台按钮权限完全一致
- [ ] 权限编码已在目标租户与目标系统完整菜单树按业务身份查重；同一业务多处 `v-auth` 未被误报，不同业务同码或跨父级/类型/路由资源冲突已停止写入
- [ ] 每次管理端新增/更新前重新执行精确查重，批量写入没有跳过单项唯一性判断
- [ ] 管理端写入仅在明确授权、环境、运行时 Token、租户和父菜单定位齐全时执行；写入前精确查重、写入后 API 复核，凭据未落盘
- [ ] 业务表单使用 `useForm` 的 `validateForm/resetForm/clearFormValidate`；校验成功后才进入提交状态，提交期间禁用，成功后关闭并刷新
- [ ] 业务页面未直接调用表单实例的 `validate/resetFields/clearValidate`
- [ ] 父子组件自定义事件及访问组件 ref 的事件使用 `@事件="具名方法"`，未直接绑定或调用组件 ref 成员，也未用内联箭头函数访问 ref
- [ ] 具名事件方法通过 `ref.value?.method(...)` 安全访问子组件公开方法

## 消息提示与弹出框

- [ ] 只使用 `import { useMessage, useMessageBox } from '/@/hooks/message';`
- [ ] 普通提示使用 `useMessage().info/warning/success/error`
- [ ] 弹出框使用 `useMessageBox().confirm/warning/success/error/info/prompt`
- [ ] 未从 `element-plus` 导入或调用 `ElMessage`、`ElMessageBox`、`Message`、`MessageBox`
- [ ] 未自行实现 Toast、消息组件、通知队列或二次消息 Hook
- [ ] 未使用 `const { message, messageBox } = useMessage()`
- [ ] 用户可见固定文案使用 i18n；取消确认作为正常分支处理
- [ ] 仅新增、编辑、删除、启停、保存、提交、导入等变更操作在请求 `catch` 中使用 `useMessage().error(...)`
- [ ] 字典、下拉、列表、详情、初始化和刷新等只读加载的 `catch` 未调用 `useMessage()`，并按需要维护局部错误态、空态或重试状态

## 组件与样式

- [ ] 组件选择顺序为全局组件/Hooks → `@fxft/ui-plus` → Element Plus → 页面私有组件
- [ ] 未将左侧强调条批量用于标题、卡片或内容分区；保留的强调条均表达明确的选中、状态、分类或项目既有设计语义
- [ ] 普通视觉层级优先由字体、留白、布局、分隔或背景建立，同页及同业务模块不存在无语义的强调条重复
- [ ] 顶部或摘要工具栏已有主操作时，空态未重复放置相同按钮；重试和状态独有恢复操作除外
- [ ] 自定义可点击区域具备键盘焦点，非必要动效适配 `prefers-reduced-motion`
- [ ] 生成前核对 `src/components/index.ts`，未虚构全局组件
- [ ] Flex 高度链路、`min-height: 0`、滚动区域和主题变量符合最新版样式规范
- [ ] 普通内容滚动区域使用 `el-scrollbar`，未使用 `overflow: auto/scroll` 或 `overflow-auto/overflow-y-auto` 等原生滚动写法
- [ ] `el-table`、`el-tree`、`el-select` 等已有内置滚动能力的组件使用自身能力，未额外嵌套 `el-scrollbar`
- [ ] 远程样式有正确 scope，不重置无 scope 的 `body`、`html` 或 `.el-*`
- [ ] import 资源经 `getStaticResourceUrl`，public 资源经 `getPublicResourceUrl`

## 模块联邦与专项组件

- [ ] 远程页面不依赖提供方 `main.ts` 的全局注册副作用
- [ ] 模块联邦配置已在修改前后运行 `aura-module-federation-check`，Web 开发技能负责实现而检查技能只提供基线/复检
- [ ] Element Plus 保持本地依赖，未加入 Module Federation shared
- [ ] expose、i18n、Tailwind、页面 CSS 和静态资源按最新版规范适配
- [ ] 地图使用 `FxftMap`，未重复接入底层地图 SDK
- [ ] 单路/多路视频使用 `FxftVideoPlayer` / `FxftMultiVideoPlayer`
- [ ] 实例、监听器、定时器、Worker、地图和播放器在卸载时正确清理

## 代码注释

- [ ] 页面或复杂组件文件头说明用途、模块和业务角色
- [ ] 已按所选页面模式列出注释锚点；查询卡片页的实际查询/筛选、工具栏、卡片列表、空态、分页区块均有中文注释
- [ ] `props`、`emits` 字段有具体中文业务说明
- [ ] 复杂模板区块、组合条件，以及卡片点击与内部操作的事件阻断说明触发场景或交互边界
- [ ] API 特殊契约、Header、上传下载或兼容逻辑说明来源
- [ ] `watch`、`nextTick`、DOM、Teleport、模块联邦、资源清理和 `:deep()` 第三方样式覆盖说明 Why
- [ ] 必要时使用 `TODO:`、`FIXME:`、`PERF:`、`HACK:`、`DEPRECATED:`
- [ ] 注释与代码同步，无翻译代码的噪音注释和大段废弃注释代码
- [ ] 已记录每个关键注释的位置及其覆盖的 Why、契约或边界；不按注释行数验收
- [ ] 中文内容为 UTF-8 无 BOM，无乱码
