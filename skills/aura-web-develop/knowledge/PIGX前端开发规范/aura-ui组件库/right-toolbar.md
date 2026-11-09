# AuraRightToolbar 右侧工具栏

公共子入口 `@fxft/aura-ui/right-toolbar`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

表格工具栏，提供搜索区显隐、导出按钮和刷新入口。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraRightToolbar from '@fxft/aura-ui/right-toolbar';
import { ref } from 'vue';

const showSearch = ref(true);
</script>

<template>
  <AuraRightToolbar v-model:showSearch="showSearch" :export="false" @query-table="() => console.log('由业务重新查询')" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| showSearch | 搜索框的显示/隐藏状态，支持 v-model:showSearch 双向绑定 | `boolean` | `true` | 否 |
| export | 导出按钮的权限标识或布尔值。`true` 表示总是显示，字符串表示需要权限验证 | `string \| boolean \| null` | `null` | 否 |
| search | 是否显示搜索按钮 | `boolean` | `true` | 否 |
| gutter | 右侧外边距为该值的一半；0 时不设置内联间距 | `number` | `10` | 否 |
| exportLoading | 导出按钮的加载状态，用于显示加载动画 | `boolean` | `false` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:showSearch | 点击搜索按钮，值为 !showSearch | value: boolean |
| queryTable | 点击刷新；模板用 @query-table | 无 |
| exportExcel | 点击可见导出按钮；模板用 @export-excel | 无 |

## Slots

| 插槽名 | 说明 | 参数 |
| --- | --- | --- |
| default | 工具栏附加按钮 | 无 |

## v-model

`v-model:showSearch` 绑定搜索区是否显示，值为 `boolean`。

## 注意事项

- 组件只发送操作事件，查询表格和导出文件由调用方处理。
- export 为权限字符串时读取 kit 权限上下文；权限未就绪、上下文缺失或无权限时隐藏。true 始终显示，false、空字符串、null 隐藏。
- 使用 v-model:showSearch 控制搜索区。search=false 隐藏搜索切换按钮，不会自行隐藏页面中的搜索表单。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraRightToolbar: DefineComponent<{
  showSearch?: boolean;
  export?: string | boolean | null;
  search?: boolean;
  gutter?: number;
  exportLoading?: boolean;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:showSearch': (showSearch: boolean) => void;
  queryTable: () => void;
  exportExcel: () => void;
}>;

export default AuraRightToolbar;
```

API 资料来自 `docs/component/right-toolbar.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
