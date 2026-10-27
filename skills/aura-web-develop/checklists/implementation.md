# 实现检查清单

本清单用于功能开发，或用户明确要求验证/报告、真实项目强制门禁命中的整理任务，并只采用所请求范围。普通纯注释/说明整理不运行本清单及其扫描、自检、测试、构建和报告门槛，按[快速路径](../references/development-review-workflow.md)人工核对含义与差异范围、项目格式化后直接交付；完整注释和业务说明标准不减。

## 工程与职责

- [ ] 本次调用的外部技能均已核对实际可用性；开发自检若明确使用仓库源码已记录路径/版本/模式能力与未安装状态，缺失项未假称已调用
- [ ] 技能安装仅在用户明确授权后执行；拒绝或安装失败时已按可降级/必需边界处理
- [ ] 页面实现完成后已明确说明使用 Codex 内置浏览器自查，未用外部 Chrome、`agent-browser` 或仅看源码代替
- [ ] 页面、页面私有组件、Composable、API、类型和 i18n 职责分离
- [ ] i18n 已按全项目、业务域、页面专属三层复用；新增 key 前已搜索同义文案，跨页面重复文案未落入各自业务目录
- [ ] 已解析 API/OpenAPI/类型中的枚举与 `@dictKey`，并逐项核对筛选、表格、详情和表单；字典筛选/表单使用 `AuraDictSelect` 或项目字典选项，标签展示必须使用 `AuraDictTag`，纯文本必须使用 `AuraDictText`，覆盖嵌套/历史记录；没有手写 map/find/switch/三元/getLabel/el-tag 转换、页面伪字典或对应 `*Name` 直出；非展示编码判断不误报
- [ ] 用户可见 label、title、placeholder、按钮、列名、卡片、Dialog/Drawer、空态、校验和消息均走 `t()` / `$t()`；已复用 common，跨两个及以上业务模块的文案已上提到业务域 i18n，zh/en key 同步存在
- [ ] 所有可编辑或筛选控件均有 i18n placeholder；例外使用 `data-placeholder-exempt` 并有相邻中文原因说明
- [ ] 路由页只保留布局、查询主状态和子组件编排；两个及以上业务 Dialog/Drawer 已拆为页面私有组件，复杂单弹窗也未内联堆积列表、表单和请求状态
- [ ] 仅供弹窗使用的详情、候选项和业务列表由弹窗持有，并在公开 `open` 流程中加载；父页面、组件挂载阶段和 `immediate` 监听未提前请求
- [ ] 父页面只传记录 ID、已选 ID 等操作上下文；保存后只刷新仍打开且确有需要的关联弹窗
- [ ] 文件与变量有业务语义，目录和命名符合最新版工程规范及相邻模块
- [ ] 项目内部 import 使用 `/@/`，没有错误的 `@/`
- [ ] 只修改需求范围内文件，不覆盖已有业务代码
- [ ] 本次代码新增、修改或重构完成后已自动执行项目本地 Prettier，并遵循项目配置和 `.prettierignore`
- [ ] Prettier 仅格式化本次修改的受支持文件，未改动锁文件、生成物和第三方目录

## 请求与接口

- [ ] 已按[已有业务对象的数据加载约束](../references/business-object-loading.md)确定数据来源；页面、Tab、面板、抽屉、弹窗均按实际场景加载详情，入口只传标识与上下文，操作类型没有由 ID 是否存在统一推断
- [ ] 未将表格行、卡片、树节点、地图点位、Props、路由 state 或缓存直接作为详情/表单；回填与提交显式映射，加载失败不回退入口快照，旧请求不覆盖新目标
- [ ] 请求统一使用 `/@/config/aura/request`，未直接创建 axios 实例
- [ ] API 命名遵循当前业务域与最新版规范，未强制旧版五段式
- [ ] 字段名、类型、必填性和单值/数组结构与明确接口契约一致
- [ ] 未硬编码域名、IP、Token、Cookie、密码或部署前缀
- [ ] 未在业务代码中自行处理认证失效、清 Token 或跳转登录

## Hooks、表格与表单

- [ ] 日期时间处理遵循[日期与时间处理强制约束](../references/date-time-guidelines.md)，统一使用 `dayjs` 或基于它的公共工具；未用字符串截取、手写运算、原生 `Date` 运算或其它日期库替代
- [ ] 时间空值与无效值、显示精度、接口格式、时间戳单位和时区按契约处理；必要的原生 `Date` 通过 `.toDate()` 转换，插件复用项目注册
- [ ] `<script setup>` 的 `ref/reactive/computed/shallowRef/shallowReactive` 数据绑定未与模板中的任何全局或局部组件标签同名或规范化后同名
- [ ] `useTable(state)` 传入响应式状态，未从返回值解构不存在的 `state`
- [ ] 表格绑定 `tableStyle.cellStyle`、`tableStyle.headerCellStyle`
- [ ] 表格需要撑满剩余高度时，表格区通过纵向 Flex 与 `min-height: 0` 参与高度链路，`el-table` 同时使用 `class="el-table--fit"` 和 `flex: 1`，未使用 `100vh` 或固定像素高度
- [ ] 分页、排序、下载和对齐复用真实 `useTable` 能力
- [ ] 新增或修改的普通 `el-select` 默认使用 `filterable`；明确关闭或组件不兼容时有原因说明
- [ ] 权限按钮使用当前项目 `v-auth` 约定
- [ ] 只含受限操作的容器按子操作权限并集使用 `permissions.any([...])` 控制可见性；表格操作列、卡片操作区、受限工具栏分组、下拉触发器和批量选择列在所有子操作均无权限时不留下空壳
- [ ] 具体按钮仍保留各自 `v-auth`；行状态只在权限通过后继续细分，包含查看、刷新等无权限操作的混合容器未被整体隐藏
- [ ] 正式新业务页面、菜单入口或操作按钮已生成菜单/按钮权限清单；多个相同 `v-auth` 已按唯一编码合并为一条后台按钮权限，并保留全部引用位置
- [ ] 用户指定的权限编码未被改写；未指定编码由真实“业务标识 + 功能动作”组成并遵循当前项目格式，页面 `v-auth` 与后台按钮权限完全一致
- [ ] 权限编码已在目标租户与目标系统完整菜单树按业务身份查重；同一业务多处 `v-auth` 未被误报，不同业务同码或跨父级/类型/路由资源冲突已停止写入
- [ ] 每次管理端新增/更新前重新执行精确查重，批量写入没有跳过单项唯一性判断
- [ ] 新增正式页面命中时已主动询问是否同步创建/更新；管理端写入仅在用户确认同步与写入、环境、运行时 Token、租户和父菜单定位齐全时执行；写入前精确查重、写入后 API 复核，凭据未落盘
- [ ] 已询问页面是否配置远程菜单；不配置远程菜单时已撤销本次新增的业务 expose（包括 `src/hooks/moduleFederation.ts` 对应配置），保留框架标准 expose 和其他实际依赖所需的模块联邦配置
- [ ] 业务表单使用 `useForm` 的 `validateForm/resetForm/clearFormValidate`；校验成功后才进入提交状态，提交期间禁用，成功后关闭并刷新
- [ ] 业务页面未直接调用表单实例的 `validate/resetFields/clearValidate`
- [ ] 父子组件自定义事件及访问组件 ref 的事件使用 `@事件="具名方法"`，未直接绑定或调用组件 ref 成员，也未用内联箭头函数访问 ref
- [ ] 具名事件方法通过 `ref.value?.method(...)` 安全访问子组件公开方法

## 消息提示与弹出框

- [ ] 只使用 `import { useMessage, useMessageBox } from '/@/config/aura/index';`
- [ ] 普通提示使用 `useMessage().info/warning/success/error`
- [ ] 弹出框使用 `useMessageBox().confirm/warning/success/error/info/prompt`
- [ ] 未从 `element-plus` 导入或调用 `ElMessage`、`ElMessageBox`、`Message`、`MessageBox`
- [ ] 未自行实现 Toast、消息组件、通知队列或二次消息 Hook
- [ ] 未使用 `const { message, messageBox } = useMessage()`
- [ ] 用户可见固定文案使用 i18n；取消确认作为正常分支处理
- [ ] 仅新增、编辑、删除、启停、保存、提交、导入等变更操作在请求 `catch` 中使用 `useMessage().error(...)`
- [ ] 字典、下拉、列表、详情、初始化和刷新等只读加载的 `catch` 未调用 `useMessage()`，并按需要维护局部错误态、空态或重试状态

## 组件与样式

- [ ] 普通业务 UI 的组件选择顺序为 aura-web-kit Hook / aura-ui 组件 → Element Plus → 页面私有组件，未将 `@fxft/ui-plus` 作为通用优先复用层级
- [ ] 进入 Element Plus 选型阶段时，已使用 Codex 内置浏览器检查官方组件总览和候选组件文档，并核对当前项目版本支持的公开 API
- [ ] 能由 Element Plus 官方组件或官方组合方案满足的业务 UI 未自行重写；确需自行实现时，职责清单和交付中已记录候选组件及不适用原因
- [ ] 未将左侧强调条批量用于标题、卡片或内容分区；保留的强调条均表达明确的选中、状态、分类或项目既有设计语义
- [ ] 普通视觉层级优先由字体、留白、布局、分隔或背景建立，同页及同业务模块不存在无语义的强调条重复
- [ ] 顶部或摘要工具栏已有主操作时，空态未重复放置相同按钮；重试和状态独有恢复操作除外
- [ ] 自定义可点击区域具备键盘焦点，非必要动效适配 `prefers-reduced-motion`
- [ ] 生成前核对已安装 aura-ui 导出、类型和 AuraUIResolver，未虚构组件
- [ ] Flex 高度链路、`min-height: 0`、滚动区域和主题变量符合最新版样式规范
- [ ] 普通内容滚动区域使用 `el-scrollbar`，未使用 `overflow: auto/scroll` 或 `overflow-auto/overflow-y-auto` 等原生滚动写法
- [ ] `el-table`、`el-tree`、`el-select` 等已有内置滚动能力的组件使用自身能力，未额外嵌套 `el-scrollbar`
- [ ] 远程样式有正确 scope，不重置无 scope 的 `body`、`html` 或 `.el-*`
- [ ] import 资源经 `getStaticResourceUrl`，public 资源经 `getPublicResourceUrl`

## 模块联邦与专项组件

- [ ] 远程页面不依赖提供方 `main.ts` 的全局注册副作用
- [ ] 若页面涉及模块联邦，配置已在修改前后运行 `aura-module-federation-check`，Web 开发技能负责实现而检查技能只提供基线/复检；不配置远程菜单时仅确认未登记远程菜单
- [ ] Element Plus 的本地依赖与 shared singleton 按[模块联邦规范](../knowledge/PIGX前端开发规范/模块联邦开发技术规范.md)核对，不沿用旧的禁止共享要求
- [ ] expose、i18n、Tailwind、页面 CSS 和静态资源按最新版规范适配
- [ ] 地图使用 `FxftMap`，未重复接入底层地图 SDK
- [ ] 单路/多路视频使用 `FxftWebVideo` / `FxftWebMultiVideo`
- [ ] 实例、监听器、定时器、Worker、地图和播放器在卸载时正确清理

## 代码注释

- [ ] 已从完整授权源码按[注释覆盖表及评审清单](../references/code-comment-guidelines.md)逐项核对方法、变量/服务、模板语义元素、业务组件实例和关键执行阶段；中文含义、相邻归属与真实行为一致，缺项整改，不以命名、数量或零散注释判通过
- [ ] API/类型按[声明字段门槛](../references/code-comment-guidelines.md#声明字段完整性门槛)覆盖完整授权文件，每声明字段自己的相邻中文、方法各入参与返回分别核验；可选结构诊断按请求/项目门禁运行，不代替语义结论
- [ ] 已按[开发闭环](../references/development-review-workflow.md)维护必要业务说明与真实阅读入口；已有图与实现一致，独立新流程按需补图，未机械新增总览/图/索引
- [ ] 纯整理差异仅注释/文档，既有功能偏差只记录，不扩大授权；注释细则的格式、生命周期、编码及同步要求已按上述 canonical 资料核对
