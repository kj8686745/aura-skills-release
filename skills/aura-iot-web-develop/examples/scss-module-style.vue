<template>
  <section class="device-panel">
    <header class="device-panel__header">
      <h3>设备趋势</h3>
      <el-button type="primary">刷新</el-button>
    </header>

    <div class="device-panel__chart"></div>
  </section>
</template>

<script setup lang="ts">
// 示例：当样式包含复杂 BEM 结构或 Element Plus 穿透时，才写 SCSS。
</script>

<style scoped lang="scss">
.device-panel {
  border: 1px solid var(--el-border-color-light);
  border-radius: 12px;
  padding: 16px;
  background: var(--el-color-white);
  color: var(--el-text-color-primary);

  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 16px;

    h3 {
      margin: 0;
      color: var(--el-text-color-primary);
      font-size: 16px;
      font-weight: 600;
    }
  }

  &__chart {
    min-height: 280px;
    border-radius: 8px;
    background: var(--el-fill-color-lighter);
  }

  :deep(.aura-button) {
    font-weight: 500;
  }
}
</style>
