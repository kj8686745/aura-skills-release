# Mock 开发工作流

## 何时启用 Mock

优先使用 Apifox MCP 联调。仅在以下情况启用 Mock：
- Apifox MCP 不可用或未配置
- 后端接口尚未实现
- 离线开发环境

## 启用步骤

### 1. 检查并安装依赖

检查项目根目录的 `package.json`，查看 `devDependencies` 中是否已有 `vite-plugin-mock` 和 `mockjs`。

若缺失，执行安装：

```bash
pnpm add vite-plugin-mock mockjs -D
```

安装后确认 `package.json` 中出现这两个包再继续。

### 2. vite.config.ts 注册插件

在现有 `plugins` 数组中追加 `viteMockServe`（不要替换已有插件）：

```ts
import { viteMockServe } from 'vite-plugin-mock'
import { loadEnv } from 'vite'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd())
  return {
    plugins: [
      // ...其他已有插件保持不变
      viteMockServe({
        mockPath: 'mock',
        localEnabled: env.VITE_USE_MOCK === 'true',
        watchFiles: true,
      }),
    ],
  }
})
```

### 3. 配置环境变量

**`.env.development`**（开发环境开启）：

```
VITE_USE_MOCK=true
```

**`.env.production`**（生产环境不加此变量，Mock 自动关闭）。

如果项目根目录没有 `.env.development`，新建该文件并写入上面一行。

---

## Mock 数据格式规范

nexus 的 `request.ts` 响应拦截器在 `code !== 200` 时执行 `Promise.reject`，业务层进 catch。

**成功响应**（必须）：
```ts
{ code: 200, msg: 'success', data: any }
```

**分页数据**（`useTable` 期望的结构）：
```ts
{
  code: 200,
  msg: 'success',
  data: {
    records: [],  // 不能用 list、rows 等别名
    total: 0,
  }
}
```

**业务错误**（request.ts 会 reject，前端进 catch）：
```ts
{ code: 400, msg: '错误原因', data: null }
```

---

## Mock 文件命名规则

与 `src/api/` 目录对应，放在 `mock/` 下：

```
src/api/system/user.ts       →  mock/system/user.ts
src/api/mp/wx-account.ts     →  mock/mp/wx-account.ts
```

---

## 查询表格页模板

```ts
// mock/system/user.ts
import type { MockMethod } from 'vite-plugin-mock'
import Mock from 'mockjs'

export default [
  // fetchList → GET /system/user/page
  {
    url: '/system/user/page',
    method: 'get',
    timeout: 300,
    response: ({ query }) => {
      const { current = 1, size = 10 } = query
      return {
        code: 200,
        msg: 'success',
        data: Mock.mock({
          total: 45,
          [`records|${size}`]: [{
            'id|+1': (Number(current) - 1) * Number(size) + 1,
            username: '@name',
            realName: '@cname',
            'status|1': [0, 1],
            createTime: '@datetime("yyyy-MM-dd HH:mm:ss")',
          }],
        }),
      }
    },
  },

  // addObj → POST /system/user
  {
    url: '/system/user',
    method: 'post',
    response: () => ({ code: 200, msg: 'success', data: null }),
  },

  // putObj → PUT /system/user
  {
    url: '/system/user',
    method: 'put',
    response: () => ({ code: 200, msg: 'success', data: null }),
  },

  // delObjs → DELETE /system/user/{ids}
  {
    url: '/system/user/:ids',
    method: 'delete',
    response: () => ({ code: 200, msg: 'success', data: null }),
  },
] as MockMethod[]
```

---

## 接口联调完成后的处理

通过 Apifox MCP 或接口文档联调通过的接口，用 `/* ... */` 块注释注释掉对应 MockMethod 块，**不要删除**，保留作为数据结构参考：

```ts
export default [
  /* fetchList 已通过 MCP 联调 — 2026-06-09
  {
    url: '/system/user/page',
    method: 'get',
    timeout: 300,
    response: ({ query }) => { ... },
  },
  */

  // addObj 尚未联调，保持开启
  {
    url: '/system/user',
    method: 'post',
    response: () => ({ code: 200, msg: 'success', data: null }),
  },
] as MockMethod[]
```

注释格式：`/* <接口描述> 已通过 MCP 联调 — <日期> */`，便于追溯。

---

## 注意事项

- URL 不含 `/api` 前缀（`request.ts` 的 `baseURL` 已处理）
- 不要在 Mock 文件中写入真实 token 或业务凭证
