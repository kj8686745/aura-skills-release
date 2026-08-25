<script setup lang="ts">
withDefaults(
  defineProps<{
    title: string
    description?: string
  }>(),
  {
    description: '',
  },
)
</script>

<template>
  <section class="rounded-[var(--el-border-radius-base)] border border-[var(--el-border-color-lighter)] bg-[var(--el-bg-color)] shadow-[var(--el-box-shadow-light)]">
    <header class="flex items-center justify-between gap-3 border-b border-[var(--el-border-color-lighter)] px-4 py-3">
      <div class="min-w-0">
        <h3 class="truncate text-base font-medium text-[var(--el-text-color-primary)]">
          {{ title }}
        </h3>
        <p v-if="description" class="mt-1 text-sm text-[var(--el-text-color-secondary)]">
          {{ description }}
        </p>
      </div>

      <div v-if="$slots.actions" class="shrink-0">
        <slot name="actions" />
      </div>
    </header>

    <div class="p-4">
      <slot />
    </div>
  </section>
</template>
