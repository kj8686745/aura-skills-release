# 模板：defineModel 双向绑定组件

## 适用场景

- 输入框封装。
- 选择器封装。
- 开关组件。
- 查询条件中的复合输入。
- 父组件希望使用 `v-model` 简化双向同步。

## 模板

```vue
<script setup lang="ts">
const modelValue = defineModel<string>({ default: '' })

withDefaults(
  defineProps<{
    label?: string
    placeholder?: string
    disabled?: boolean
    clearable?: boolean
  }>(),
  {
    label: '',
    placeholder: '请输入',
    disabled: false,
    clearable: true,
  },
)
</script>

<template>
  <div class="flex items-center gap-2">
    <span v-if="label" class="shrink-0 text-sm text-[var(--el-text-color-regular)]">
      {{ label }}
    </span>
    <el-input
      v-model="modelValue"
      :placeholder="placeholder"
      :disabled="disabled"
      :clearable="clearable"
    />
  </div>
</template>
```

## 多模型模板

适合范围选择、起止时间等场景：

```vue
<script setup lang="ts">
const start = defineModel<string>('start', { default: '' })
const end = defineModel<string>('end', { default: '' })

withDefaults(
  defineProps<{
    disabled?: boolean
  }>(),
  {
    disabled: false,
  },
)
</script>

<template>
  <div class="flex items-center gap-2">
    <el-input v-model="start" :disabled="disabled" placeholder="开始值" />
    <span class="text-[var(--el-text-color-placeholder)]">至</span>
    <el-input v-model="end" :disabled="disabled" placeholder="结束值" />
  </div>
</template>
```

## 使用示例

```vue
<script setup lang="ts">
import DemoInput from '@/components/DemoInput/index.vue'

const keyword = ref('')
</script>

<template>
  <DemoInput v-model="keyword" label="关键字" />
</template>
```

## 要点

- Vue 3.4+ 建议使用 `defineModel`，减少手写 `modelValue` 和 `update:modelValue` 样板代码。
- 双向绑定组件不得直接修改父级其它状态。
- 复杂异步选项、远程搜索等逻辑应抽成 composable 或通过 props 注入。
