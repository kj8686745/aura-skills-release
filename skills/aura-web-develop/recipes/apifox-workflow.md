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
- 当前 `/@/config/aura/request` 类型和调用方式
- 对应页面模式

API 命名跟随当前业务域和最新版规范，不强制历史五段式。

## 3. 生成或修正 API

- 请求统一走 `/@/config/aura/request`。
- 生成明确的 TypeScript 请求与响应类型。
- 已明确的字段完全按契约落地，不增加旧字段、多字段兜底或单值/数组转换。
- API 函数添加简体中文用途注释；特殊 Header、Blob、上传或兼容逻辑说明来源。
- API 层不重复弹出页面级成功消息。
- 查询按[查询提交契约](../references/query-select-contract.md#查询条件在提交边界格式化)在 API 边界使用已安装且已核实的 request `queryFormat` 配置，核对最终请求空键缺失与有效假值；不把查询格式化应用到写入或导出外层协议字段。

## 4. 配置 useTable

`useTable(state)` 接收响应式状态，不返回 `state`：

下例的 `fetchList` 是已在 API 边界按上述契约格式化条件的查询函数；该 Hook 示例本身不实现字段处理。只有消费者安装包实际支持该请求配置时才能使用 `queryFormat`，不能把当前基线版本或文档示例当成已安装证据。

```ts
const state = reactive<BasicTableProps>({
  queryForm: {},
  pageList: fetchList,
});

const { getDataList, tableStyle } = useTable(state);
```

web-kit `1.6.18` 起只支持 `current/size` 请求与 `records/total` 分页响应，可选返回 `pages`。接口启用排序时使用 `orders: [{ column, asc }]`；接口协议不同的，只在项目已有 API 适配边界按真实契约明确转换请求与响应，公共 Hook 和页面仍使用统一分页结构；不配置已移除的 `props.item/props.totalCount`，不维护多套分页状态或添加多字段兼容。

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
import { useMessage, useMessageBox } from '/@/config/aura/index';
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
