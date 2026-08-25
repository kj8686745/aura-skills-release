<script setup lang="ts">
const keyword = defineModel<string>({ default: '' })

withDefaults(
  defineProps<{
    label?: string
    placeholder?: string
    disabled?: boolean
  }>(),
  {
    label: '关键字',
    placeholder: '请输入关键字',
    disabled: false,
  },
)
</script>

<template>
  <div class="flex items-center gap-2">
    <span class="shrink-0 text-sm text-[var(--el-text-color-regular)]">
      {{ label }}
    </span>
    <el-input
      v-model="keyword"
      class="min-w-64"
      :placeholder="placeholder"
      :disabled="disabled"
      clearable
    />
  </div>
</template>
