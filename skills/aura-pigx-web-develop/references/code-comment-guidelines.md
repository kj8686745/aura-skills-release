# Vue 项目前端代码注释与规范

本规范整合《Vue 项目前端代码注释与规范指南》，并结合 PIGX 模块联邦（综合端）的 Vue 3、TypeScript、Module Federation 和业务页面约束。

## 目录

1. 核心原则
2. SFC 结构与文件头
3. Template 注释
4. Script 注释
5. Props 与 Emits
6. 响应式状态与副作用
7. API、Store 与 Composable
8. Style 注释
9. 标准标记
10. 好坏注释对比
11. 评审清单

## 1. 核心原则

### 解释 Why，少写 What

- 代码和命名应表达做什么、怎么做。
- 注释补充业务背景、设计原因、接口契约、边界条件、性能取舍和框架避坑。
- 不写“设置 loading 为 true”“调用查询接口”等翻译代码的注释。

### 保持同步

- 修改逻辑时同步更新相关注释。
- 删除过时、矛盾或误导性的注释。
- 废弃代码直接删除并交给 Git 保存历史，不保留大段注释代码。

### 重构优先

- 一段逻辑需要大段文字才能解释时，先拆函数、优化命名或抽离 Composable。
- 注释不能替代清晰的类型、变量名和组件职责。

### 中文与编码

- 新增注释、文档、错误提示使用简体中文。
- 新增文本文件使用 UTF-8 无 BOM。
- 技术标识、类型名、函数名和标准标记保留英文。

## 2. SFC 结构与文件头

Vue SFC 默认按以下顺序组织：

```text
1. <script setup lang="ts">
2. <template>
3. <style scoped>
```

新增页面级组件或复杂公共组件在文件顶部添加说明：

```vue
<!--
 * @description 用户资料卡片，负责头像、基本信息和权限标签展示
 * @module 用户中心/用户资料
 * @business 支持用户查看和维护个人资料
-->
```

- `@description`、`@module`、`@business` 使用真实业务语义。
- 团队或项目明确要求作者、日期管理时，可增加 `@author`、`@date`；不得虚构作者或生成无意义日期。
- 简单、职责由文件名即可明确的内部小组件，可不写冗长文件头，但公开 Props/Emits 仍需说明。

## 3. Template 注释

大型模板按业务区块划分：

```vue
<template>
  <div class="layout-padding">
    <!-- 查询区：按名称和状态筛选设备 -->
    <section>...</section>

    <!-- 列表区：展示分页数据和行级操作 -->
    <section>...</section>

    <!-- 编辑弹窗：新增和编辑共用 -->
    <DeviceForm ref="formRef" />
  </div>
</template>
```

复杂条件渲染说明业务触发场景：

```vue
<!-- 仅在账号已认证、未停用且拥有编辑权限时显示编辑入口 -->
<el-button v-if="isAuthed && !isSuspended && canEdit" @click="handleEdit">
  {{ $t('common.editBtn') }}
</el-button>
```

- 条件超过两个、表达式包含业务组合判断或循环存在特殊过滤时补充说明。
- 不给每个普通 `div`、表单项或按钮逐行加注释。

### 页面模式注释锚点

- 实现前从所选正式页面模式提取实际存在的主要区块，作为本页注释锚点；交付时逐项列出位置与覆盖原因。
- 查询卡片页必须为实际存在的查询/筛选区、工具栏、卡片列表、空态、分页保留中文区块注释。可合并相邻区块的说明，但不得只保留其中一项。
- 卡片整体可点击而内部存在编辑、删除、状态切换等操作时，说明事件阻断的交互边界，避免操作触发详情跳转。
- 没有查询、工具栏或分页的页面不补虚假锚点；不按注释数量或行数验收。

## 4. Script 注释

长 `<script setup>` 可按区域分组：

```ts
// ==================== Props 与 Emits ====================
// ==================== 响应式状态 ====================
// ==================== 计算属性 ====================
// ==================== 监听器与副作用 ====================
// ==================== 生命周期 ====================
// ==================== 事件处理 ====================
```

- 仅在文件较长、分组能明显提升阅读效率时使用分区线。
- 区域名称使用简体中文，分区顺序随实际依赖调整。
- 简短组件不为了形式完整添加空分区。

## 5. Props 与 Emits

字段逐项写明业务含义、可选性、默认值或事件载荷：

```ts
interface Props {
  /** 当前编辑记录 ID；为空时进入新增模式 */
  id?: string;
  /** Teleport 目标选择器，由父业务页提供 */
  appendTo?: string;
  /** 展示模式：compact 为紧凑，full 为完整 */
  mode?: 'compact' | 'full';
}

const props = withDefaults(defineProps<Props>(), {
  appendTo: '.device-management',
  mode: 'compact',
});

const emit = defineEmits<{
  /** 保存成功后通知父页面刷新；reset 为 true 时回到第一页 */
  (e: 'refresh', reset?: boolean): void;
  /** 返回父业务页并保留父页面查询状态 */
  (e: 'back'): void;
}>();
```

禁止只写“ID”“模式”“回调”等没有业务上下文的说明。

## 6. 响应式状态与副作用

非显而易见的状态说明业务用途：

```ts
// 记录未保存修改数量，用于拦截离开当前编辑页
const unsavedChangesCount = ref(0);
```

`watch`、`watchEffect`、`nextTick`、定时器、事件监听和 DOM 操作说明触发原因与清理时机：

```ts
// 用户 ID 变化时必须清空旧表单并重新加载，避免展示上一位用户的数据
watch(
  () => props.userId,
  (userId) => {
    resetForm();
    if (userId) loadUser(userId);
  },
  { immediate: true },
);

// HACK: Element Plus Dialog 完成 DOM 挂载后才能清除内部表单校验
await nextTick();
formRef.value?.clearValidate();
```

地图、视频、WebSocket、Worker、轮询和模块联邦实例必须说明创建、更新、隐藏恢复和销毁时机。

## 7. API、Store 与 Composable

API 函数说明用途和特殊契约：

```ts
// 分页查询设备列表，字段结构以当前接口文档定义为准
export const fetchList = (params: DevicePageQuery) =>
  request({ url: '/device/page', method: 'get', params });
```

- 特殊 Header、Blob、上传、单值/数组契约和兼容逻辑写明来源。
- Store 文件顶部说明共享状态的业务范围，避免把页面局部状态放入全局 Store。
- Composable 涉及缓存、副作用、监听或跨页面状态时说明生命周期和清理方式。
- 调用 `useMessageBox().confirm()` 的取消分支可说明“用户主动取消，无需提示”。

## 8. Style 注释

样式注释重点说明布局原因、第三方覆盖和模块联邦隔离：

```scss
/* Flex 子项必须允许收缩，否则表格会撑破综合端内容区 */
.table-wrap {
  min-height: 0;
}

// HACK: 覆盖 Element Plus 内部 wrapper，以匹配当前业务主题的聚焦边框
:deep(.el-input__wrapper) {
  border-color: var(--el-color-primary);
}
```

- 普通 Tailwind class、简单尺寸和颜色无需注释。
- `:deep()`、`!important`、复杂选择器、关键帧和远程 scope 必须说明原因。
- 覆盖第三方组件前先确认公开 Props、Slots 和主题变量无法满足。

## 9. 标准标记

| 标记 | 使用场景 | 示例 |
|---|---|---|
| `TODO:` | 待实现或待重构 | `// TODO(负责人): 接入组织权限接口（Issue-204）` |
| `FIXME:` | 已知缺陷或隐患 | `// FIXME: 高频切换会产生请求竞态` |
| `PERF:` | 性能取舍 | `// PERF: 使用虚拟列表避免万级数据卡顿` |
| `HACK:` | 框架或第三方组件避坑 | `// HACK: 标签页显示后重新计算图表尺寸` |
| `DEPRECATED:` | 弃用说明 | `// DEPRECATED: 请改用新的批量接口` |

- 能关联负责人、Issue 或移除条件时一并注明。
- 不用 `TODO` 代替本次任务应完成的代码。

## 10. 好坏注释对比

| 不推荐 | 推荐 |
|---|---|
| `const visible = ref(false); // visible 为 false` | 无需注释，变量名已自解释 |
| `const d = ref(7); // 延迟天数` | 改名为 `delayDays` |
| `// 调用 nextTick` | `// 等待弹窗 DOM 挂载后再初始化表格` |
| 注释掉几十行旧代码 | 删除旧代码，由 Git 保存历史 |
| `// 查询列表` | 仅在字段转换、分页契约特殊时说明原因 |

## 11. 评审清单

- [ ] 页面或复杂组件文件头说明了用途、模块和业务角色。
- [ ] `props`、`emits` 字段有具体中文业务说明。
- [ ] 复杂模板区块和组合条件说明了业务场景。
- [ ] 已按页面模式核对实际存在的注释锚点；查询卡片页覆盖查询/筛选、工具栏、卡片列表、空态、分页。
- [ ] 卡片点击与内部操作存在事件阻断时，已说明交互边界。
- [ ] 响应式副作用、DOM 时序和生命周期清理说明了 Why。
- [ ] API 特殊契约、兼容、上传下载和 Header 说明了来源。
- [ ] Module Federation、Teleport、地图、视频和第三方样式覆盖说明了原因。
- [ ] 标准标记可搜索、可追踪，没有无责任主体的长期 TODO。
- [ ] 修改逻辑时已同步更新注释，过时注释和废弃代码已删除。
- [ ] 没有翻译代码表面含义的噪音注释。
- [ ] 所有新增中文为 UTF-8 无 BOM，无乱码。
