# 模板：API 封装模块

## 适用场景

- 新增或维护 `src/api/` 下的接口模块。
- 页面、hooks、store 需要调用后端接口。
- 需要定义列表、详情、保存、删除、字典等接口函数。

## 强制规则

- API 文件必须放在 `src/api/`，页面不得直接调用 axios。
- API 文件命名必须先读 `references/naming-conventions.md`，按业务域和业务对象命名，不能只按接口路径中的泛化片段命名。
- 必须复用 `@/utils/request` 中的 `get`、`post`、`request`、`download`、`ApiResponse`、`RequestConfig`。
- 项目内部路径使用 `@/`，不要使用 `/@/`。
- 函数名必须描述业务动作，不要使用 `api1`、`query` 这类含义不清的命名。
- 注释、类型说明和错误提示必须使用简体中文。
- 初期可以使用 `unknown` 占位，但交付前应尽量收窄为明确类型。

## 推荐文件结构与命名

API 文件必须按业务语义命名：

```text
src/api/<business-domain>.ts
```

示例：

```text
src/api/device-statistics-report.ts     # 终端数量统计报表
src/api/device-management.ts            # 设备管理
src/api/platform-config.ts              # 平台配置
```

如果模块较大：

```text
src/api/<module>/
├── index.ts
└── types.ts
```

## 命名决策表

| 判断项 | 命名依据 |
|--------|----------|
| 页面是报表下载 | 使用报表业务名，例如 `device-statistics-report.ts` |
| 页面是管理列表 | 使用管理对象，例如 `device-management.ts` |
| 接口路径含 `online` 但页面语义是终端统计 | 不使用 `online.ts`，改用 `device-statistics-report.ts` |
| 多个页面共享同一业务域接口 | 使用业务域聚合名，例如 `device.ts` |
| 接口只服务一个明确页面 | 使用页面业务名 |

## 基础模板

```ts
import { get, post, request, type ApiResponse, type RequestConfig } from '@/utils/request'

export interface DemoQuery {
  keyword?: string
  status?: string
}

export interface DemoItem {
  id: string
  name: string
  status: string
}

/** 查询示例列表 */
export function queryDemoList(params: DemoQuery): Promise<ApiResponse<DemoItem[]>> {
  return get('/demo/queryList.action', params)
}

/** 保存示例数据 */
export function saveDemo(data: Partial<DemoItem>): Promise<ApiResponse<boolean>> {
  return post('/demo/save.action', data)
}
```

## 分页列表接口

```ts
export interface PageQuery {
  pageNum: number
  pageSize: number
}

export interface PageResult<T> {
  list: T[]
  total: number
  pageNum?: number
  pageSize?: number
}

export interface DeviceQuery extends PageQuery {
  deviceName?: string
  onlineStatus?: string
}

export interface DeviceItem {
  id: string
  deviceName: string
  onlineStatus: string
}

/** 分页查询设备列表 */
export function queryDevicePage(params: DeviceQuery): Promise<ApiResponse<PageResult<DeviceItem>>> {
  return get('/iot/device/queryPage.action', params)
}
```

## JSON 提交接口

当接口需要明确提交 JSON 时，通过 `request` 设置请求头：

```ts
/** JSON 方式保存配置 */
export function saveConfigByJson(
  data: Record<string, unknown>,
  config: RequestConfig = {},
): Promise<ApiResponse<boolean>> {
  return request<boolean>({
    ...config,
    url: '/iot/config/save.action',
    method: 'POST',
    data,
    headers: {
      ...config.headers,
      'Content-Type': 'application/json;charset=UTF-8',
    },
  })
}
```

## 字典和选项接口

```ts
export interface OptionItem {
  label: string
  value: string
  disabled?: boolean
}

/** 查询设备状态选项 */
export function queryDeviceStatusOptions(): Promise<ApiResponse<OptionItem[]>> {
  return get('/iot/device/queryStatusOptions.action')
}
```

## 页面中调用约定

```ts
import { queryDevicePage } from '@/api/device'

const loadData = async () => {
  const res = await queryDevicePage(queryParams.value)
  tableData.value = res.data.list
}
```

## 禁止

- 禁止 API 文件使用 `api.ts`、`online.ts`、`common.ts`、`index.ts` 等无法表达业务对象的命名；模块目录中的 `index.ts` 仅允许作为 `src/api/<business-domain>/index.ts` 入口。
- 禁止页面直接 `import axios from 'axios'`。
- 禁止在 API 模块中写死 token、Cookie、登录态。
- 禁止在 API 模块中操作 DOM 或页面组件状态。
- 禁止把接口路径散落在多个页面中。
- 禁止长期保留 `Promise<ApiResponse<unknown>>` 而不补类型。
