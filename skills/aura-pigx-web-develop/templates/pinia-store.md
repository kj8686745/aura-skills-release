# Pinia Store 模板

## 使用场景

跨页面共享状态（如用户信息、全局配置）。单页面局部状态不需要 store，直接用 `reactive`。

## 标准模板

```typescript
// src/stores/<业务域>/<业务对象>.ts
// 示例: src/stores/mp/wx-account-config.ts

import { defineStore } from 'pinia'
import { ref } from 'vue'
import { getObj } from '/@/api/mp/wx-account'

// 共享微信公众号配置状态，仅用于跨页面复用当前账号配置
export const useWxAccountConfigStore = defineStore('mp/wx-account-config', () => {
  const config = ref<Record<string, any> | null>(null)
  const loading = ref(false)

  // 拉取当前账号配置，页面进入或账号切换后调用
  const fetchConfig = async () => {
    loading.value = true
    try {
      const res = await getObj('current')
      config.value = res.data
    } finally {
      loading.value = false
    }
  }

  // 清空缓存配置，退出模块或账号失效时调用
  const clearConfig = () => {
    config.value = null
  }

  return { config, loading, fetchConfig, clearConfig }
})
```

## 持久化（pinia-plugin-persist）

```typescript
export const useUserStore = defineStore(
  'user',
  () => {
    const token = ref('')
    return { token }
  },
  {
    persist: {
      key: 'nexus-user',
      storage: sessionStorage,
      paths: ['token'],
    },
  }
)
```

## 使用示例

```typescript
import { useWxAccountConfigStore } from '/@/stores/mp/wx-account-config'

const store = useWxAccountConfigStore()
onMounted(() => store.fetchConfig())
```

## 命名约定

- 文件：`src/stores/<业务域>/<业务对象>.ts`
- defineStore id：`<业务域>/<业务对象>`（kebab-case）
- 函数名：`use<PascalCase业务对象>Store`
