# Hooks 使用规范

以当前项目 `src/hooks/` 源码、类型定义和最新版 PIGX 规范为准。使用前先读取真实实现，禁止根据历史技能示例猜测返回值。

## useTable

`useTable(state)` 接收并补全一个响应式 `BasicTableProps` 对象，返回操作方法和 `tableStyle`，不返回 `state`。

```ts
import { BasicTableProps, useTable } from '/@/hooks/table';
import { fetchList } from '/@/api/device/device';

const state = reactive<BasicTableProps>({
  queryForm: {},
  pageList: fetchList,
  descs: ['create_time'],
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

<Pagination
  v-bind="state.pagination"
  @size-change="sizeChangeHandle"
  @current-change="currentChangeHandle"
/>
```

- 查询和重置通常调用 `getDataList()`，回到第一页。
- 保留当前页刷新调用 `getDataList(false)`。
- 文本、数字等差异化对齐通过 `tableAlign` 按列 `prop` 配置。
- 不从返回值解构 `state`，不手写重复的分页、排序和下载逻辑。

## useForm

先读取当前 `/@/hooks/form.ts` 的真实签名。使用项目表单 Hook 重置字段和校验，不在多个弹窗中复制清理逻辑。

```ts
import { useForm } from '/@/hooks/form';

const { resetForm } = useForm();
```

若最新版页面模式明确使用 `nextTick(() => dataFormRef.value?.resetFields())`，按页面模式和真实 Hook 能力选择，不强行套用旧模板。

## useMessage 与 useMessageBox

唯一导入方式：

```ts
import { useMessage, useMessageBox } from '/@/hooks/message';
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
import { useDict } from '/@/hooks/dict';

const { common_status } = useDict('common_status');
```

字典展示和选择优先复用当前项目已注册的 `DictTag`、`DictSelect` 等组件，生成前检查 `src/components/index.ts`。

## useParam

```ts
import { useParam } from '/@/hooks/param';

const maxUploadSize = await useParam('sys.upload.maxSize');
```

## useEcharts

看板和图表先读取真实 `/@/hooks/echarts.ts` 及其 README，使用公开的初始化、更新、空态和 resize 能力，不直接操作内部 ECharts 实例。

## 封装缺失

1. 用 `rg "useXxx" src/hooks src/views` 确认项目和业务域是否已有实现。
2. 检查公司组件库或 VueUse 是否已有稳定能力。
3. 仅在确认无法复用时新增业务 Composable。
4. 页面私有逻辑优先放在页面目录 `composables/`；真正跨业务通用后再提升到 `src/hooks/`。
5. 新增副作用必须说明生命周期和清理时机。
