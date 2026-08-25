# 模板：带插槽容器组件

## 适用场景

- 通用卡片容器。
- 页面区块容器。
- 工具栏容器。
- 列表容器。
- 需要让调用方注入标题、操作区、默认内容、底部内容。

## 模板

```vue
<script setup lang="ts">
withDefaults(
  defineProps<{
    title?: string
    description?: string
    bodyClass?: string
  }>(),
  {
    title: '',
    description: '',
    bodyClass: '',
  },
)
</script>

<template>
  <section class="rounded-[var(--el-border-radius-base)] border border-[var(--el-border-color-lighter)] bg-[var(--el-bg-color)]">
    <header class="flex items-start justify-between gap-3 border-b border-[var(--el-border-color-lighter)] px-4 py-3">
      <slot name="header">
        <div class="min-w-0">
          <h3 v-if="title" class="truncate text-base font-medium text-[var(--el-text-color-primary)]">
            {{ title }}
          </h3>
          <p v-if="description" class="mt-1 text-sm text-[var(--el-text-color-secondary)]">
            {{ description }}
          </p>
        </div>
      </slot>

      <div v-if="$slots.actions" class="shrink-0">
        <slot name="actions" />
      </div>
    </header>

    <div class="p-4" :class="bodyClass">
      <slot />
    </div>

    <footer v-if="$slots.footer" class="border-t border-[var(--el-border-color-lighter)] px-4 py-3">
      <slot name="footer" />
    </footer>
  </section>
</template>
```

## 作用域插槽模板

适合列表容器把 loading、empty 等状态暴露给调用方：

```vue
<template>
  <slot :loading="loading" :is-empty="items.length === 0" />
</template>
```

## 使用示例

```vue
<PageSection title="设备列表" description="展示当前节点下的设备">
  <template #actions>
    <el-button type="primary">新增</el-button>
  </template>

  <DeviceTable />

  <template #footer>
    <div class="text-right text-sm text-[var(--el-text-color-secondary)]">共 10 条</div>
  </template>
</PageSection>
```

## 要点

- 带插槽组件只提供布局和扩展点，不内置具体业务 API。
- 建议提供默认插槽和常用具名插槽：`header`、`actions`、`footer`。
- 样式使用 Element Plus 主题变量。
