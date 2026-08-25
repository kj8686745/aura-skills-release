<template>
  <!-- 示例：Tailwind 任意值绑定 Element Plus 主题变量 -->
  <section
    class="rounded-xl border border-[var(--el-border-color-light)] bg-[var(--el-color-white)] p-5 text-[var(--el-text-color-primary)] shadow-[var(--el-box-shadow-light)]"
  >
    <div class="flex items-center justify-between gap-3">
      <div class="min-w-0 flex-1">
        <h3 class="truncate text-base font-semibold">设备状态</h3>
        <p class="mt-1 text-sm text-[var(--el-text-color-secondary)]">
          所有颜色都来自 Element Plus 主题变量。
        </p>
      </div>

      <el-tag type="success">在线</el-tag>
    </div>

    <div class="mt-4 grid grid-cols-3 gap-3">
      <div class="rounded-lg bg-[var(--el-fill-color-lighter)] p-3">
        <p class="text-xs text-[var(--el-text-color-secondary)]">总数</p>
        <p class="mt-1 text-xl font-semibold text-[var(--el-text-color-primary)]">128</p>
      </div>
      <div class="rounded-lg bg-[var(--el-color-primary-light-9)] p-3">
        <p class="text-xs text-[var(--el-text-color-secondary)]">在线</p>
        <p class="mt-1 text-xl font-semibold text-[var(--el-color-primary)]">96</p>
      </div>
      <div class="rounded-lg bg-[var(--el-color-warning-light-9)] p-3">
        <p class="text-xs text-[var(--el-text-color-secondary)]">告警</p>
        <p class="mt-1 text-xl font-semibold text-[var(--el-color-warning)]">3</p>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
// 布局、间距、字号、圆角全部使用 Tailwind。
// 颜色、背景、边框、阴影全部绑定 Element Plus CSS 变量。
</script>
