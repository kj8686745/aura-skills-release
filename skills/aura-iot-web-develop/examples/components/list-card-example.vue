<script setup lang="ts">
interface CardItem {
  id: string
  title: string
  description: string
  status: 'online' | 'offline'
}

withDefaults(
  defineProps<{
    items: CardItem[]
    loading?: boolean
  }>(),
  {
    loading: false,
  },
)

const statusMap = {
  online: {
    label: '在线',
    class: 'text-[var(--el-color-success)] bg-[var(--el-color-success-light-9)]',
  },
  offline: {
    label: '离线',
    class: 'text-[var(--el-text-color-secondary)] bg-[var(--el-fill-color-light)]',
  },
}
</script>

<template>
  <div v-loading="loading" class="min-h-24">
    <el-empty v-if="!loading && items.length === 0" description="暂无数据" />

    <div v-else class="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
      <article
        v-for="item in items"
        :key="item.id"
        class="rounded-[var(--el-border-radius-base)] border border-[var(--el-border-color-lighter)] bg-[var(--el-bg-color)] p-4 shadow-[var(--el-box-shadow-light)]"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h3 class="truncate text-base font-medium text-[var(--el-text-color-primary)]">
              {{ item.title }}
            </h3>
            <p class="mt-1 line-clamp-2 text-sm text-[var(--el-text-color-secondary)]">
              {{ item.description }}
            </p>
          </div>
          <span class="shrink-0 rounded-full px-2 py-0.5 text-xs" :class="statusMap[item.status].class">
            {{ statusMap[item.status].label }}
          </span>
        </div>

        <div class="mt-3 flex justify-end gap-2 border-t border-[var(--el-border-color-lighter)] pt-3">
          <el-button text type="primary">详情</el-button>
          <el-button text type="primary">编辑</el-button>
        </div>
      </article>
    </div>
  </div>
</template>
