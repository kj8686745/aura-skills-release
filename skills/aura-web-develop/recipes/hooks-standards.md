# Hooks 使用规范

1.2.0 以已安装 `@fxft/aura-web-kit` 的公开声明、项目 `src/config/aura` 绑定和最新版 PIGX 规范为准。先查 [能力清单](../knowledge/PIGX前端开发规范/aura-web-kit能力清单与接入规范.md)，禁止根据历史技能示例猜测返回值。

## useTable

`useTable(state)` 接收并补全一个响应式 `BasicTableProps` 对象，返回操作方法和 `tableStyle`，不返回 `state`。

```ts
import { BasicTableProps, useTable } from '/@/config/aura/index';
import { fetchList } from '/@/api/device/device';

const state = reactive<BasicTableProps>({
  queryForm: {},
  pageList: fetchList,
  orders: [{ column: 'create_time', asc: false }],
  tableAlign: {
    name: 'left',
    amount: 'right',
  },
});

const {
  getDataList,
  currentChangeHandle,
  sizeChangeHandle,
  sortChangeHandle,
  downBlobFile,
  tableStyle,
} = useTable(state);
```

```vue
<el-table
  :data="state.dataList"
  v-loading="state.loading"
  :cell-style="tableStyle.cellStyle"
  :header-cell-style="tableStyle.headerCellStyle"
  @sort-change="sortChangeHandle"
>
  <el-table-column prop="name" label="名称" show-overflow-tooltip />
</el-table>

<AuraPagination
  v-bind="state.pagination"
  @size-change="sizeChangeHandle"
  @current-change="currentChangeHandle"
/>
```

- 查询和重置通常调用 `getDataList()`，回到第一页。
- 保留当前页刷新调用 `getDataList(false)`。
- 文本、数字等差异化对齐通过 `tableAlign` 按列 `prop` 配置。
- 不从返回值解构 `state`，不手写重复的分页、排序和下载逻辑。
- web-kit `1.6.18` 起，分页请求仅使用 `current/size`，响应读取 `records/total`，`pages` 为可选返回字段。接口协议不同的，只在项目已有 API 适配边界按真实契约明确转换请求与响应；公共 Hook 和页面仍使用统一分页结构，不把 `total/records/pages` 作为请求参数。
- 接口启用排序时使用 `orders: OrderItem[]`（`column`、`asc`）；未配置或清空后省略，不发送 `descs/ascs`。GET 对象数组使用 `orders[0].column`、`orders[0].asc`，POST JSON 使用对象数组，复用公共请求序列化。
- `pageSizes/layout` 只用于分页组件。旧 `props.item/props.totalCount` 映射已移除；响应契约不一致时先确认接口，在已有 API 适配边界转换为标准结构；不恢复 Hook 内映射、不维护多套分页状态或添加多字段兜底。

## useForm

所有业务表单必须使用 `@fxft/aura-web-kit/hooks/form` 的 `useForm`。先读取当前 Hook 的真实签名，统一通过 Hook 校验、重置字段和清理历史校验，不在页面或多个弹窗中复制表单实例调用。

### 触发与适用范围

凡涉及业务表单的开发、功能修改或重构即触发本节，不依赖需求是否出现“校验”“重置”或“useForm”。页面表单、Dialog、Drawer、内嵌编辑和它们的私有组件采用同一要求；查询表单有校验或重置时也使用对应 Hook 方法。命中授权范围的旧表单不能以“相邻代码一直这样写”为由跳过接入。仅以 `el-form` 排版且没有这些生命周期的只读区域，不为导入 Hook 增加无效逻辑；非 Element Plus 表单先核对适配结构，无法覆盖的能力明确记缺口，保留真实组件校验协议，不强行接入布尔适配器或伪造 API。

功能修改在本次授权业务块内补齐接入，不扩展为全项目旧表单迁移；纯注释/说明整理保持可执行代码不变，按入口快速路径记录既有偏差。`form.ts` 是公共包实现文件，不要求页面旁新增同名文件，也不得复制到项目 `src/hooks/`。

```ts
import { useForm } from '@fxft/aura-web-kit/hooks/form';

const { clearFormValidate, resetForm, validateForm } = useForm();
```

- 提交前使用 `await validateForm(formRef)`；只有返回 `true` 后才设置提交 loading 和调用写接口。
- 弹窗关闭时使用 `resetForm(formRef, form, initialForm)` 恢复初始值。
- 弹窗打开并完成新增初始化或编辑数据回填后使用 `await clearFormValidate(formRef)`，避免上一次操作的校验错误残留。
- 仅清理部分字段时可传入字段名或字段名数组；不得绕过 Hook 直接调用 Element Plus 表单实例的 `validate/clearValidate/resetFields`。
- 缺少 `validateForm` 或 `clearFormValidate` 时核对已安装包版本和公开声明，按项目升级范围处理；不得恢复本地 `src/hooks/form.ts` 副本。

### 当前扩展契约

以下能力已在 web-kit 源码提交 `df7206233306299fdb4d327a22f5d34c8177faed` 实现。旧版已发布 `1.9.0/1.9.1` 不因版本号相同就具有本轮实现；只有项目已安装的公开声明和实际包内容可证明支持，技能不自动升级项目依赖，也不改变既有框架版本基线。来源与发布状态见[表单维护记录](../references/form-hook-source.json)。

- 字段联动或分步校验必须使用支持版本的 `validateFormFields(formRef, props)`，复用实例的 `validateField`；业务不得直接调用实例 `validateField` 或在页面重新包装对应公共能力。需要该能力而安装包缺失时记明确缺口，按任务授权升级；不能假称已接入或返回成功。字段级校验不替代业务要求的最终整表校验。
- `props` 支持 `'name'`、`['startAt', 'plannedRestoreAt']`、点路径 `'rows.0.name'` 和单字段分段路径 `[['rows', '0', 'name']]`。空路径、未挂载、缺能力、false 或异常均不放行；必须核对实际 FormItem prop、规则及挂载，不能将未注册字段的组件返回值当作已经校验的证据。
- 新 `resetForm` 通过 VueUse `useCloned` 的手动模式和自定义结构化克隆策略隔离初值；保持模型身份，仍将原自有字段置 `undefined` 再覆盖初值。完整默认值由业务初值工厂提供，不用共享浅引用冒充独立副本；旧包不得假称已具备嵌套隔离。
- 克隆支持的数据类型以实际策略为准：保留 `undefined`、Date、Map/Set 等结构化数据语义，要求环境支持 `structuredClone`；根层 `toRaw` 不递归解包显式嵌套 Proxy。函数、DOM、嵌套 Proxy 等不支持值在重置前失败，业务应映射为真实 DTO，不能静默浅拷贝兜底。现有其他克隆封装不在本次表单接入中顺带迁移。

### 编码与验收

- 编码前核对项目声明、锁定及已安装版本的 `exports`、`hooks/form` 类型，识别表单 ref、模型、初始值及打开/回填/关闭/提交入口；框架源码的新方法不等于项目已安装能力。
- 按实际操作使用所需方法，不强制每个表单解构全部三项。查询重置不凭空增加提交校验；提交表单不能仅解构 `resetForm` 就继续手写 `validate`。方法改名、别名导入或经私有 Composable 转发时，追踪到最终公共 Hook 调用，不能只检查 `useForm` 字符串。
- `validateForm` 返回 `false` 时必须结束提交，未挂载也不得继续写请求。异步校验开始前建立防重保护（如 `validating`），覆盖校验与提交全程并正确释放，校验成功后再进入提交状态；只有提交 loading 无法阻止校验等待期间的重复触发。表单关闭或切换记录后，旧校验结果不能提交新对象。
- 交付前在已有开发记录中简记本次各表单的真实调用位置或符号：整表/字段校验、重置、回填后清校验、校验/提交防重的适用结果；无对应操作写明依据，不另建逐字段矩阵或报告。检索 `validate/validateField/resetFields/clearValidate` 只是候选，需核对对象和调用链；其他对象的同名方法、公共包内部实现不算业务绕过。
- 纳入范围仍直接调用上述实例方法、仅导入未消费、缺少必需方法或未取得调用证据时，不得宣称表单接入通过；按实际情况整改或记阻断/缺证。代表性行为覆盖无效输入不请求、连续点击一次提交、复用后无旧校验、重置符合业务初值；执行范围沿既有检查选择表，不因本节重复全量构建。

## useMessage 与 useMessageBox

唯一导入方式：

```ts
import { useMessage, useMessageBox } from '/@/config/aura/index';
```

正确用法：

```ts
useMessage().success(t('common.optSuccessText'));
useMessage().error(t('message.operationFailed'));
await useMessageBox().confirm(t('common.delConfirmText'));
```

禁止：

```ts
// 错误：真实 useMessage() 不返回 message 和 messageBox
const { message, messageBox } = useMessage();
```

禁止业务代码直接导入 Element Plus 的 `ElMessage`、`ElMessageBox`、`Message` 或 `MessageBox`。完整规则见 `references/message-feedback-guidelines.md`。

## useDict

```ts
import { useDict } from '/@/config/aura/index';

const { common_status } = useDict('common_status');
```

字典标签/文本展示必须使用 `AuraDictTag` / `AuraDictText`；选择使用 `AuraDictSelect` 或项目字典选项，生成前检查已安装 aura-ui 的导出、类型与 `AuraUIResolver` 配置。

## useParam

```ts
import { useParam } from '/@/config/aura/index';

const maxUploadSize = useParam('sys.upload.maxSize'); // Ref<string>，按需读取 .value
```

## useECharts

看板和图表先读取真实 `/@/config/aura/echarts` 绑定及 `@fxft/aura-web-kit/hooks/echarts` 声明，使用 `useECharts` 公开的初始化、更新、空态和 resize 能力，不直接操作内部 ECharts 实例。

## 封装缺失

1. 先查 web-kit 能力清单、exports 和声明，再用 `rg "useXxx" src/config/aura src/hooks src/views` 确认项目实例与业务实现。
2. 检查公司 UI 规范或 VueUse 是否已有稳定能力。
3. 仅在确认无法复用时新增业务 Composable。
4. 按[职责决策表](../knowledge/PIGX前端开发规范/文件组织与职责拆分.md)选择结构：简单状态可留 Vue，少量私有 Hook 可同级，多组职责才进页面 `composables/`；同模块共用放模块，项目跨模块共用才进 `src/hooks/`。跨项目能力先查 web-kit，项目业务留项目。
5. 新增副作用必须说明生命周期和清理时机。
