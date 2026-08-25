# 模板：基础展示组件

## 适用场景

- 状态标签。
- 信息摘要块。
- 空状态展示。
- 只读指标或说明组件。

## 模板

```vue
<script setup lang="ts">
import { computed } from 'vue'

export interface StatusMeta {
  label: string
  type?: 'primary' | 'success' | 'warning' | 'danger' | 'info'
}

const props = withDefaults(
  defineProps<{
    title: string
    description?: string
    status?: StatusMeta
  }>(),
  {
    description: '',
  },
)

const statusClass = computed(() => {
  const type = props.status?.type || 'info'
  const classMap: Record<string, string> = {
    primary: 'text-[var(--el-color-primary)] bg-[var(--el-color-primary-light-9)]',
    success: 'text-[var(--el-color-success)] bg-[var(--el-color-success-light-9)]',
    warning: 'text-[var(--el-color-warning)] bg-[var(--el-color-warning-light-9)]',
    danger: 'text-[var(--el-color-danger)] bg-[var(--el-color-danger-light-9)]',
    info: 'text-[var(--el-text-color-secondary)] bg-[var(--el-fill-color-light)]',
  }
  return classMap[type]
})
</script>

<template>
  <section class="rounded-[var(--el-border-radius-base)] border border-[var(--el-border-color-lighter)] bg-[var(--el-bg-color)] p-4 shadow-[var(--el-box-shadow-light)]">
    <div class="flex items-start justify-between gap-3">
      <div class="min-w-0">
        <h3 class="truncate text-base font-medium text-[var(--el-text-color-primary)]">
          {{ title }}
        </h3>
        <p v-if="description" class="mt-1 text-sm text-[var(--el-text-color-secondary)]">
          {{ description }}
        </p>
      </div>

      <span
        v-if="status"
        class="shrink-0 rounded-full px-2 py-0.5 text-xs"
        :class="statusClass"
      >
        {{ status.label }}
      </span>
    </div>
  </section>
</template>
```

## 要点

- 使用 `computed` 管理展示类名，避免模板中堆复杂表达式。
- Tailwind 任意值必须绑定 Element Plus 变量。
- 组件只负责展示，不直接请求接口。
