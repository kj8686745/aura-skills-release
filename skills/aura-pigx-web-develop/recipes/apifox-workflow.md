# Apifox MCP 联调工作流

## 1. 读取定义

通过可用的 Apifox MCP、用户提供的接口文件或正式接口文档确认：

- URL 与 HTTP Method
- Query、Path、Header、Body 字段
- 字段名、类型、必填性和单值/数组/对象结构
- 响应体、分页列表和总数字段
- 认证与租户要求

不得猜测接口路径或字段。

## 2. 检查项目约定

先读取：

- `knowledge/PIGX前端开发规范/工程与代码生成规范.md`
- 当前业务域 `src/api/` 相邻模块
- 当前 `/@/utils/request` 类型和调用方式
- 对应页面模式

API 命名跟随当前业务域和最新版规范，不强制历史五段式。

## 3. 生成或修正 API

- 请求统一走 `/@/utils/request`。
- 生成明确的 TypeScript 请求与响应类型。
- 已明确的字段完全按契约落地，不增加旧字段、多字段兜底或单值/数组转换。
- API 函数添加简体中文用途注释；特殊 Header、Blob、上传或兼容逻辑说明来源。
- API 层不重复弹出页面级成功消息。

## 4. 配置 useTable

`useTable(state)` 接收响应式状态，不返回 `state`：

```ts
const state = reactive<BasicTableProps>({
  queryForm: {},
  pageList: fetchList,
  props: {
    item: 'records',
    totalCount: 'total',
  },
});

const { getDataList, tableStyle } = useTable(state);
```

响应字段不是 `records` / `total` 时，只按真实响应修改 `props.item`、`props.totalCount`，不改造后端数据制造假兼容。

## 5. 发起真实请求

验证：

- HTTP 状态与业务成功码
- 请求字段、结构和序列化方式
- 响应字段与 TypeScript 类型
- 分页、详情、新增、修改、删除和特殊操作
- 认证失败是否由项目请求层统一处理

不得把真实 Token、Cookie、密码写入代码、规划文件或交付文档。

## 6. 页面反馈

页面需要成功、失败或确认反馈时只能使用：

```ts
import { useMessage, useMessageBox } from '/@/hooks/message';
```

不得直接引入 Element Plus Message/MessageBox，不自行实现消息组件。

## 7. 记录结果

逐项列出方法、路径、结果和差异：

```text
✓ GET /order/page — 返回 records[10]，total=42
✓ POST /order — 新增成功
✗ GET /order/{id} — 后端 404，保留为风险
```

## MCP 不可用

1. 说明当前无法读取或执行 Apifox 用例。
2. 使用用户已提供的正式接口资料完成静态类型对照。
3. 不编造“已联调通过”。
4. 在交付中列出需要人工或后续环境验证的接口。
