# 模板：列表 / 卡片组件

## 适用场景

- 指标卡片列表。
- 设备卡片列表。
- 可操作数据块。
- 需要支持 loading、empty、操作插槽的列表展示。

## 模板

```vue
<script setup lang="ts" generic="T extends { id: string }">
withDefaults(
  defineProps<{
    items: T[]
    loading?: boolean
    emptyText?: string
  }>(),
  {
    loading: false,
    emptyText: '暂无数据',
  },
)
</script>

<template>
  <div v-loading="loading" class="min-h-24">
    <el-empty v-if="!loading && items.length === 0" :description="emptyText" />

    <div v-else class="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
      <article
        v-for="item in items"
        :key="item.id"
        class="rounded-[var(--el-border-radius-base)] border border-[var(--el-border-color-lighter)] bg-[var(--el-bg-color)] p-4 shadow-[var(--el-box-shadow-light)]"
      >
        <slot name="item" :item="item">
          <pre class="text-sm text-[var(--el-text-color-regular)]">{{ item }}</pre>
        </slot>

        <div v-if="$slots.actions" class="mt-3 flex justify-end gap-2 border-t border-[var(--el-border-color-lighter)] pt-3">
          <slot name="actions" :item="item" />
        </div>
      </article>
    </div>
  </div>
</template>
```

## 使用示例

```vue
<DemoCardList :items="deviceList" :loading="loading">
  <template #item="{ item }">
    <h3 class="text-base font-medium text-[var(--el-text-color-primary)]">
      {{ item.name }}
    </h3>
    <p class="mt-1 text-sm text-[var(--el-text-color-secondary)]">
      {{ item.description }}
    </p>
  </template>

  <template #actions="{ item }">
    <el-button text type="primary" @click="handleDetail(item)">详情</el-button>
  </template>
</DemoCardList>
```

## 要点

- 列表组件通过 slot 暴露 item，避免写死业务字段。
- loading 和 empty 由组件统一处理。
- 操作按钮通过 `actions` 插槽注入。
- 颜色、边框、阴影使用 Element Plus 主题变量。
