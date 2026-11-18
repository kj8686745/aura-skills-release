# AuraPagination 分页

公共子入口 `@fxft/aura-ui/pagination`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

控制列表页码和每页条数，显示总数与分页导航。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraPagination from '@fxft/aura-ui/pagination';
import { ref } from 'vue';

const current = ref(1);
const size = ref(10);
</script>

<template>
  <AuraPagination :current="current" :size="size" :total="100" @current-change="current = $event" @size-change="size = $event" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| current | 当前页码 | `number` | `1` | 否 |
| size | 每页显示条数 | `number` | `10` | 否 |
| total | 总条数 | `number` | `0` | 否 |
| pageSizes | 每页显示条数选择器的选项 | `number[]` | `[1, 10, 20, 50, 100, 200]` | 否 |
| layout | 组件布局 | `string` | `'total, sizes, prev, pager, next, jumper'` | 否 |
| teleported | 是否将下拉菜单插入至 body 元素 | `boolean` | `true` | 否 |
| customClass | 添加到分页根节点的业务样式类，用于间距、对齐等覆盖 | `string` | `''` | 否 |
| background | 是否为分页按钮添加背景色（对应 Element Plus `el-pagination` 的 `background`） | `boolean` | `true` | 否 |

## Events

| 事件名 | 说明 | 回调参数 |
| --- | --- | --- |
| sizeChange | Element Plus 页容量变化；模板用 @size-change | size: number |
| currentChange | Element Plus 当前页变化；模板用 @current-change | current: number |

## 注意事项

- current、size 由调用方维护；分页事件不会自动更新传入状态，也不会自动重置页码。
- disabled、hide-on-single-page、pager-count 等属性透传给 ElPagination；分页文案由 ElConfigProvider 的 locale 控制。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';
import type { PaginationProps } from 'element-plus';

declare const AuraPagination: DefineComponent<Partial<Omit<PaginationProps, 'size'>> & {
  current?: number;
  size?: number;
  customClass?: string;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  sizeChange: (size: number) => void;
  currentChange: (current: number) => void;
}>;

export default AuraPagination;
```

API 资料来自 `docs/component/pagination.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
