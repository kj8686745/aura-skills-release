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
- web-kit `1.6.18` 起，分页请求仅使用 `current/size`，响应读取 `records/total`，`pages` 为可选返回字段。API 层不得转换为 `pageNum/pageSize/pageNo/currentPage`，也不得把 `total/records/pages` 作为请求参数。
- 接口启用排序时使用 `orders: OrderItem[]`（`column`、`asc`）；未配置或清空后省略，不发送 `descs/ascs`。GET 对象数组使用 `orders[0].column`、`orders[0].asc`，POST JSON 使用对象数组，复用公共请求序列化。
- `pageSizes/layout` 只用于分页组件。旧 `props.item/props.totalCount` 映射已移除；响应契约不一致时先确认接口，不增加字段别名或多字段兜底。

## useForm

所有业务表单必须使用 `@fxft/aura-web-kit/hooks/form` 的 `useForm`。先读取当前 Hook 的真实签名，统一通过 Hook 校验、重置字段和清理历史校验，不在页面或多个弹窗中复制表单实例调用。

```ts
import { useForm } from '@fxft/aura-web-kit/hooks/form';

const { clearFormValidate, resetForm, validateForm } = useForm();
```

- 提交前使用 `await validateForm(formRef)`；只有返回 `true` 后才设置提交 loading 和调用写接口。
- 弹窗关闭时使用 `resetForm(formRef, form, initialForm)` 恢复初始值。
- 弹窗打开并完成新增初始化或编辑数据回填后使用 `await clearFormValidate(formRef)`，避免上一次操作的校验错误残留。
- 仅清理部分字段时可传入字段名或字段名数组；不得绕过 Hook 直接调用 Element Plus 表单实例的 `validate/clearValidate/resetFields`。
- 缺少 `validateForm` 或 `clearFormValidate` 时核对已安装包版本和公开声明，按项目升级范围处理；不得恢复本地 `src/hooks/form.ts` 副本。

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

字典展示和选择优先复用 `AuraDictTag`、`AuraDictSelect` 等组件，生成前检查已安装 aura-ui 的导出、类型与 `AuraUIResolver` 配置。

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
4. 页面私有逻辑放在页面目录 `composables/`；跨项目通用能力进入 web-kit 并公开导出，项目实例与业务 Hook 留在项目。
5. 新增副作用必须说明生命周期和清理时机。
