# 模板：Pinia Store

## 适用场景

- 多个页面或多个远距离组件需要共享状态。
- 状态需要跨路由保留。
- qiankun 底座传入的信息需要在子应用内统一读取。
- 业务模块存在统一的筛选条件、当前选中项、缓存数据或用户上下文。

## 是否应该使用 Pinia

先判断状态作用域：

| 场景 | 建议 |
|------|------|
| 只在单个组件内部使用 | 使用 `ref` / `reactive`，不要放入 Pinia |
| 父子组件短链路传递 | 使用 props / emits / `defineModel` |
| 页面内多个局部组件共享 | 可抽页面级 composable，必要时再用 Pinia |
| 跨页面、跨模块共享 | 使用 Pinia |
| 需要 qiankun mount/update 同步 | 使用 Pinia |

## 关于 `src/stores/user.ts`

当前项目的 `src/stores/user.ts` 适合作为以下场景参考：

- 用户上下文。
- qiankun 用户信息同步。
- localStorage 容错读取。
- `fallback` 初始状态。
- `initFromStorage` / `updateUserInfos` / `clear` 这类 action 组织方式。

但它不适合作为所有 store 的唯一模板，因为它包含用户、租户、角色、底座用户态等特定字段。通用业务 store 应按业务域重新定义 state 和 actions。

## Store 命名规则

Store 文件名、store id、导出函数名必须体现业务域和共享状态职责，命名细则见 `references/naming-conventions.md`。

```text
src/stores/device-statistics.ts
```

```ts
export const useDeviceStatisticsStore = defineStore('deviceStatistics', {})
```

禁止使用 `useDataStore`、`usePageStore`、`useCommonStore` 等过泛命名，除非确实是全局公共状态。

## 通用业务 Store 模板

```ts
import { defineStore } from 'pinia'

export interface DemoFilters {
  keyword: string
  status: string
}

export interface DemoItem {
  id: string
  name: string
  status: string
}

export interface DemoState {
  filters: DemoFilters
  currentId: string
  selectedRows: DemoItem[]
  lastLoadedAt: number | null
}

const fallback: DemoState = {
  filters: {
    keyword: '',
    status: '',
  },
  currentId: '',
  selectedRows: [],
  lastLoadedAt: null,
}

export const useDemoStore = defineStore('demo', {
  state: (): DemoState => ({
    ...fallback,
    filters: { ...fallback.filters },
    selectedRows: [],
  }),

  getters: {
    hasSelected: (state) => state.selectedRows.length > 0,
    currentKeyword: (state) => state.filters.keyword.trim(),
  },

  actions: {
    updateFilters(filters: Partial<DemoFilters>) {
      this.filters = { ...this.filters, ...filters }
    },

    updateSelectedRows(rows: DemoItem[]) {
      this.selectedRows = rows
    },

    markLoaded() {
      this.lastLoadedAt = Date.now()
    },

    resetFilters() {
      this.filters = { ...fallback.filters }
    },

    clear() {
      Object.assign(this, {
        ...fallback,
        filters: { ...fallback.filters },
        selectedRows: [],
      })
    },
  },
})
```

## 用户上下文 Store 模板

```ts
import { defineStore } from 'pinia'

export interface AppUserInfo {
  userId?: string
  userName?: string
  loginName?: string
  [key: string]: unknown
}

export interface AppUserState {
  user: AppUserInfo
  roles: Array<{ id: string; name: string; [key: string]: unknown }>
  tenantId: string
  tenantName: string
}

const fallback: AppUserState = {
  user: {},
  roles: [],
  tenantId: '',
  tenantName: '',
}

function readJsonFromStorage<T>(key: string): T | null {
  try {
    const raw = localStorage.getItem(key)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

export const useAppUserStore = defineStore('appUser', {
  state: (): AppUserState => ({ ...fallback }),

  getters: {
    isLoggedIn: (state) => !!state.user.userId,
    userName: (state) => state.user.userName || state.user.loginName || '',
  },

  actions: {
    /** 从本地存储初始化用户信息 */
    initFromStorage() {
      const account = readJsonFromStorage<Record<string, unknown>>('account')
      if (!account) return
      this.user = {
        userId: String(account.userId || ''),
        userName: String(account.name || ''),
        loginName: String(account.loginName || ''),
      }
    },

    /** 由 qiankun mount/update 调用，作为底座用户信息补充 */
    updateFromQiankun(raw: Partial<AppUserState> | null | undefined) {
      if (!raw) return
      if (raw.user?.userId) this.user = { ...this.user, ...raw.user }
      if (raw.roles?.length) this.roles = raw.roles
      if (raw.tenantId) this.tenantId = raw.tenantId
      if (raw.tenantName) this.tenantName = raw.tenantName
    },

    clear() {
      Object.assign(this, { ...fallback })
    },
  },
})
```

## 强制规则

- Store 文件名、store id、导出函数名必须按业务语义命名。
- 必须定义 state interface。
- 必须定义 fallback 初始值。
- getters 只做派生状态，不发请求，不改状态。
- actions 负责异步和状态变更。
- 必须提供 `clear` 或 `reset` 方法。
- localStorage 读取必须 try/catch 容错。
- 不要把 token、Cookie、密码写进 store。

## 禁止

- 禁止使用 `useDataStore`、`usePageStore`、`useCommonStore` 等脱离业务语义的命名。
- 禁止在 store 中直接操作 DOM。
- 禁止在 store 中直接调用组件实例方法。
- 禁止将单页面临时状态无脑放入全局 store。
- 禁止在多个 store 中重复维护同一份权威状态。
