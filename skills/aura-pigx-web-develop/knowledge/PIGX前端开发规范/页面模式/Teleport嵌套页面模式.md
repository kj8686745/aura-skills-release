# 页面模式：Teleport 嵌套页面

> Teleport 适用于同一路由内的临时覆盖层，不替代后端菜单、权限路由或模块联邦页面。使用前同时遵守[路由与菜单规范](../路由与菜单规范.md)和[开发检查清单](../开发检查清单.md)。

## 概述

在 Vue 3 中使用 `Teleport` 实现多层页面/组件的嵌套覆盖显示。每一层通过 Teleport 将内容渲染到上一层的 DOM 容器中，配合 `v-show` / `v-if` 控制层级可见性，实现类似"页面栈"的全屏覆盖效果，无需路由跳转。

## 架构图

```text
app-management/index.vue (Level 0 - 列表页)
  DOM: div.layout-padding.app-management
    |-- 列表内容 (v-show="visible")
    |-- app-config (append-to=".app-management")
         |
         v
config/index.vue (Level 1 - 配置页)
  Teleport :to="appendTo"  -->  渲染到 .app-management
    DOM: div.layout-padding.app-config
      |-- 配置内容 (v-show="visible")
      |-- access-control
            |-- application-authorization (append-to=".app-config")
                 |
                 v
ApplicationAuthorization/index.vue (Level 2 - 授权页)
  Teleport :to="appendTo"  -->  渲染到 .app-config
    DOM: div.layout-padding.application-authorization
      |-- 授权内容
```

## 核心原理

每一层组件：

1. 通过 `appendTo` prop 接收 Teleport 目标选择器
2. 使用 `Teleport :to="appendTo"` 将自身内容传送到父级 DOM 容器
3. 使用 `position: absolute; width: 100%; height: 100%; z-index: 9` 覆盖父级
4. 通过 `v-show` 控制自身可见性，实现层与层之间的切换

---

## 逐层实现

### Level 0：列表页（最外层容器）

文件：`src/views/xxx/list/index.vue`

```vue
<template>
  <div class="layout-padding my-list-page">
    <!-- 列表内容，通过 v-show 控制显隐 -->
    <div class="layout-padding-auto layout-padding-view" v-show="visible">
      <!-- 表格、搜索等 -->
    </div>

    <!-- 子页面组件，声明 Teleport 目标为当前页面的 class -->
    <detail-page ref="detailRef" @close="handleClose" append-to=".my-list-page" />
  </div>
</template>

<script setup lang="ts">
const detailRef = ref();
const visible = ref(true);

const openDetail = (id: string) => {
  detailRef.value.openDialog(id);
  visible.value = false;  // 隐藏列表
};

const handleClose = () => {
  visible.value = true;   // 恢复列表
};
</script>

<style scoped lang="scss">
.my-list-page {
  // 作为 Teleport 容器，需要定位上下文
  position: relative;
}
</style>
```

**要点：**

- 根元素需要 `position: relative` 作为 Teleport 子内容的定位参考
- 通过 `v-show="visible"` 控制列表内容的显隐
- 子组件通过 `append-to` prop 指定 Teleport 目标为当前页面的 class

---

### Level 1：详情/配置页（中间层）

文件：`src/views/xxx/detail/index.vue`

```vue
<template>
  <Teleport :to="appendTo">
    <div class="layout-padding my-detail-page" v-if="visibleConfig">
      <div class="layout-padding-auto layout-padding-view" v-show="visible">
        <!-- 详情内容：表单、标签页等 -->
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    appendTo?: string;   // Teleport 目标选择器，由父组件传入
  }>(),
  { appendTo: '.layout-padding' }
);

const emit = defineEmits<{ close: [] }>();

const visibleConfig = ref(false);  // 控制整个 Teleport 内容的挂载
const visible = ref(true);         // 控制当前层内容的显隐

const openDialog = (id: string) => {
  visibleConfig.value = true;
  // 加载数据...
};

const handleBack = () => {
  visibleConfig.value = false;
  emit('close');
};

// 供子组件调用：隐藏/显示当前层
const hidePage = () => { visible.value = false; };
const showPage = () => { visible.value = true; };

defineExpose({ openDialog });
</script>

<style scoped lang="scss">
.layout-padding {
  position: absolute;
  width: 100%;
  height: 100%;
  z-index: 9;
  top: 0;
  left: 0;
}
</style>
```

**要点：**

- 使用 `v-if="visibleConfig"` 控制整个 Teleport 分支的挂载/卸载
- 使用 `v-show="visible"` 控制内容显隐（供更深层子组件切换）
- 暴露 `hidePage()` / `showPage()` 方法供子组件调用
- Teleport 出去的根元素必须 `position: absolute` 全覆盖

---

### Level 2：弹窗/授权页（最内层）

文件：`src/components/MyDialog/index.vue`

```vue
<template>
  <Teleport :to="appendTo">
    <div class="layout-padding my-dialog" v-if="visible">
      <div class="layout-padding-auto layout-padding-view dialog-content">
        <!-- 弹窗内容 -->
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    appendTo?: string;
    usageType?: 'page' | 'component';  // 区分使用场景
  }>(),
  {
    appendTo: '.layout-padding',
    usageType: 'page',
  }
);

const emit = defineEmits<{
  onCancel: [];
  onSuccess: [];
}>();

const visible = ref(false);

const openDialog = (echoData?: any[]) => {
  // 重置状态
  visible.value = true;
  // 处理回显数据...
};

const handleCancel = () => {
  visible.value = false;
  emit('onCancel');
};

const handleSuccess = () => {
  visible.value = false;
  emit('onSuccess');
};

// 暴露方法给父组件调用
defineExpose({
  openDialog,
  handleCancel,
  // 其他更新数据的方法...
});

// keep-alive 场景：组件被缓存时自动关闭
onDeactivated(() => {
  visible.value = false;
});
</script>

<style scoped lang="scss">
.layout-padding {
  position: absolute;
  width: 100%;
  height: 100%;
  z-index: 9;
  top: 0;
  left: 0;
}
</style>
```

**要点：**

- 最内层组件，Teleport 到中间层的容器
- `usageType` 区分是作为独立页面还是嵌入组件使用
- `onDeactivated` 中重置状态，兼容 keep-alive

---

## 关键样式

每一层 Teleport 出去的根元素都需要以下样式才能正确覆盖父级：

```scss
.layout-padding {
  position: absolute;
  width: 100%;
  height: 100%;
  z-index: 9;          // 层级递增，最内层最高
  top: 0;
  left: 0;
}
```

**注意**：最外层容器（Level 0）需要设置 `position: relative` 作为定位参考。

---

## 层级切换流程

以"列表页 -> 配置页 -> 授权弹窗"为例：

```text
1. 用户点击列表页的"配置"按钮
   -> listPage.visible = false  （隐藏列表）
   -> detailRef.openDialog(id)  （打开配置页，Teleport 到 .my-list-page）

2. 用户在配置页点击"新增授权"
   -> detailPage.visible = false （隐藏配置页）
   -> dialogRef.openDialog()     （打开授权弹窗，Teleport 到 .my-detail-page）

3. 用户在授权弹窗点击"取消"
   -> dialog.visible = false     （关闭弹窗）
   -> emit('onCancel')
   -> detailPage.visible = true  （恢复配置页）

4. 用户在配置页点击"返回"
   -> detailPage.visibleConfig = false
   -> emit('close')
   -> listPage.visible = true    （恢复列表页）
```

---

## 使用方式总结

| 步骤 | 说明 |
| ---- | ---- |
| 1. 定义容器 class | 每层页面根元素定义一个唯一的 class（如 `.my-list-page`、`.my-detail-page`） |
| 2. 传递 appendTo | 父组件通过 `append-to=".my-xxx-page"` 告诉子组件 Teleport 到哪个容器 |
| 3. Teleport 渲染 | 子组件用 `Teleport :to="appendTo"` 将内容传送到目标容器 |
| 4. 绝对定位覆盖 | Teleport 出去的根元素用 `position: absolute` 覆盖整个父容器 |
| 5. v-show 切换 | 通过 `v-show` 控制每层的显隐，实现层级切换 |

---

## 与路由方案对比

| 特性 | Teleport 嵌套 | 路由跳转 |
| ---- | ------------- | -------- |
| URL 变化 | 不变 | 变化 |
| 组件状态保持 | 天然支持（keep-alive） | 需额外处理 |
| 页面切换动画 | 需自行实现 | 路由过渡动画 |
| 适用场景 | 面板/弹窗式嵌套 | 独立页面跳转 |
| 浏览器前进后退 | 不支持 | 原生支持 |

---

## 注意事项

1. **Teleport 目标必须存在**：确保 `appendTo` 指向的选择器在 DOM 中已渲染，否则 Teleport 会报错
2. **z-index 管理**：内层 z-index 应高于外层，避免被遮挡
3. **keep-alive 兼容**：如果使用 `keep-alive`，在 `onDeactivated` 中重置 visible 状态
4. **异步组件**：推荐使用 `defineAsyncComponent` 懒加载子组件，减少首屏体积
5. **事件命名**：建议统一用 `hidePage` / `showPage` 控制父级显隐，`onCancel` / `onSuccess` 处理弹窗结果
6. **scoped 样式限制**：Teleport 出去的内容不在原组件 DOM 树下，`scoped` 样式仍然生效（Vue 3 通过 data 属性追踪），但需确保目标容器样式不冲突

