# 接口文档示例：公开 OpenAPI 设备查询

> 本文是对外 OpenAPI 的设计示例，路径、签名约定、错误码、配额和版本均为示例值，不代表现行公开接口或 SDK 已发布。公开接口使用与其他 HTTP 业务接口相同的 `R<T>` 响应和 `PageResult<T>` 分页契约；HMAC 仅是该调用边界的认证方式，不改变响应结构。

## 一、接口基本信息

| 项目 | 内容 |
| --- | --- |
| 接口编号 | API-OPEN-DEVICE-001 |
| 接口名称 | 查询设备列表 |
| 契约版本/状态 | v1 / 设计示例，未发布 |
| 提供模块/项目 | 设备公开服务（示例） |
| 调用模块/项目 | 合作方系统（示例） |
| 接口边界 | 对外 OpenAPI |
| 网关路径 | `GET /openapi/v1/devices` |
| 平台 API 自动收录 | `@PlatfomApi(code = "device-query", version = "1.0.0", name = "查询设备列表", requestPath = "/openapi/v1/devices")` |
| 唯一事实来源 | 本文仅示范公开契约写法；实际项目以已发布契约和配套 SDK 为准 |

本单接口示例对应模块接口文档模板的“模块基本信息”“接口总览”“职责与调用边界”“统一认证与请求上下文”“接口逐项契约”“公共响应与错误”“幂等与兼容”“联调”“发布运行”和“完成自检”章节。由于本文只展示一个对外接口，未再单独拆分模块级接口总览文件。

## 二、认证和请求头

每次请求使用已登记的 HMAC 版本和签名头：

```http
GET /openapi/v1/devices?pageNo=1&pageSize=20
X-App-Id: app-demo
X-Sign-Version: v1
X-Timestamp: 1789954200
X-Nonce: 8f3b6f4e-7a24-4a0c-a50d-7f2e8b7b1c10
X-Signature: <HMAC-SHA256-SIGNATURE>
```

- 签名覆盖方法、路径、排序后的查询参数、时间戳、nonce 和请求体摘要；具体拼接顺序由公开 SDK 固定。
- `X-Timestamp` 只允许在登记的时间容差内；`nonce` 只能使用一次，服务端必须执行防重放校验。
- 密钥只保存在合作方服务端和 AURA 认证配置中，不出现在前端、日志、文档或错误消息中。
- 租户、数据范围和公开权限由应用登记关系确定，不接受请求体中的 `tenantId` 覆盖。

## 接口逐项契约：API-OPEN-DEVICE-001 查询设备列表

本接口的认证请求头在本节之前统一说明；本节及后续成功响应、错误、重试和兼容内容共同构成该接口的完整契约。

| 参数位置 | 参数 | 类型 | 必填 | 规则 |
| --- | --- | --- | --- | --- |
| query | `pageNo` | integer | 否 | 默认 1，最小 1 |
| query | `pageSize` | integer | 否 | 默认 20，最大 100 |
| query | `keyword` | string | 否 | 最长 64 字符，按公开设备名称或编号查询 |
| query | `status` | string | 否 | `ONLINE`、`OFFLINE` |

## 四、成功响应

HTTP 状态为 `200`，使用统一的 `R<PageResult<PublicDevice>>`：

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "records": [
      {
        "deviceId": "D-1001",
        "deviceName": "园区北门设备",
        "status": "ONLINE",
        "lastSeenAt": "2026-09-21T10:30:00+08:00"
      }
    ],
    "total": 1,
    "size": 20,
    "current": 1,
    "pages": 1
  },
  "ok": true
}
```

响应字段说明：

| 字段 | 类型 | 必返 | 业务含义 |
| --- | --- | --- | --- |
| `code` | integer | 是 | AURA 业务成功码；HTTP 状态仍由响应状态表示 |
| `msg` | string | 是 | 可安全展示的结果说明 |
| `data` | object | 是 | `PageResult<PublicDevice>` 分页结果 |
| `ok` | boolean | 否（框架兼容字段） | `code` 的只读成功标志 |
| `data.records` | array | 是 | 当前页公开设备 DTO |
| `data.total` | integer | 是 | 当前过滤条件下的总记录数 |
| `data.size` | integer | 是 | 本次实际生效的页大小 |
| `data.current` | integer | 是 | 本次实际生效的页码 |
| `data.pages` | integer | 是 | 总页数；无记录时为 `0` |

`records` 为空时返回 `[]`，不得返回 `null`；分页字段仍必须完整返回。公开字段由 `PublicDevice` DTO 控制，不能因为是对外接口而改用另一套分页字段。

公开模型只返回公开字段，不返回内部租户 ID、数据库主键、设备密钥、内部地址或原始设备报文。
`lastSeenAt` 表示供跨系统使用的设备最后在线瞬间，因此示例显式携带 `+08:00` 偏移量；调用方按带偏移量的时间解析，不把它当作无时区的中国区展示字符串。

## 五、错误契约

| HTTP | 错误码 | 场景 | 可重试 | 调用方处理 |
| --- | --- | --- | --- | --- |
| 400 | `OPEN_DEVICE_INVALID_PARAM` | 页码、页大小、状态或关键字不合法 | 否 | 修正请求 |
| 401 | `OPEN_SIGNATURE_MISSING` | 缺少签名头 | 否 | 按 SDK 重新签名 |
| 403 | `OPEN_APP_FORBIDDEN` | 应用无设备查询权限 | 否 | 联系能力提供方 |
| 429 | `OPEN_RATE_LIMITED` | 超出公开配额 | 是 | 按 `Retry-After` 延迟 |
| 500 | `OPEN_DEVICE_SERVICE_FAILED` | 服务或依赖故障 | 条件性 | 按公开 SDK 策略重试 |

错误响应：

```json
{
  "code": 429,
  "msg": "请求频率超过公开配额",
  "data": {
    "errorCode": "OPEN_RATE_LIMITED",
    "retryable": true,
    "retryAfterSeconds": 30,
    "requestId": "req-open-20260921-002"
  }
}
```

错误字段说明：

| 字段 | 类型 | 必返 | 业务含义 |
| --- | --- | --- | --- |
| `code` | integer | 是 | HTTP 失败场景对应的 AURA 业务结果码 |
| `msg` | string | 是 | 可安全展示的错误说明 |
| `data.errorCode` | string | 是 | 稳定业务错误码 |
| `data.retryable` | boolean | 是 | 是否允许按公开 SDK 的预算和幂等规则重试 |
| `data.retryAfterSeconds` | integer | 适用时 | 限流后的等待秒数 |
| `data.requestId` | string | 按链路契约 | 请求定位标识；也可由响应头或日志关联提供 |

## 六、超时、重试和幂等

- 查询接口是幂等读操作；调用方只对连接失败、明确临时 `5xx` 和 `429` 按 SDK 统一策略重试。
- `400/401/403` 不重试；签名失败不得通过重复发送相同 nonce 解决。
- 服务端设置连接、读取和整体超时；超时响应必须携带 `requestId`。
- 分页最大 `pageSize=100`，服务端必须再次限制，不能只依赖 SDK。

## 七、联调场景

| 场景 | 预期结果 |
| --- | --- |
| 合法签名 | 返回公开分页数据 |
| 时间戳过期 | 返回签名时间错误，不泄露签名细节 |
| nonce 重放 | 返回防重放错误，不重复处理 |
| 参数错误 | `400/OPEN_DEVICE_INVALID_PARAM` |
| 无权限应用 | `403/OPEN_APP_FORBIDDEN` |
| 超出配额 | `429/OPEN_RATE_LIMITED`，带重试等待时间 |
| 依赖故障 | 返回公开错误和请求标识，不泄露内部堆栈 |
| 字段兼容 | 新增可选字段不影响旧 SDK |

## 八、发布、运行和变更

| 项目 | 内容 |
| --- | --- |
| 契约版本 | v1（设计示例，未发布） |
| SDK 版本 | 未发布；实际项目填写已交付版本 |
| 运行关注项 | 签名失败率、401/403、429、5xx、耗时和调用方分布 |
| 兼容方式 | 新增可选字段；删除字段或改变错误语义必须升级版本 |
| 废弃状态 | 不适用（设计示例，未发布） |

## 九、完成自检

- [ ] HMAC 版本、签名字段和防重放约束明确；
- [ ] 公开响应使用统一的 `R<T>` 和 `PageResult<T>`，并逐字段说明类型、必返性、空值和含义；
- [ ] 未暴露内部实体、分页模型、租户字段和敏感信息；
- [ ] `400` 参数错误、认证、权限、限流和依赖错误均有契约；
- [ ] 超时、重试、配额和分页上限明确；
- [ ] 联调覆盖签名、重放、权限、限流和兼容场景。

