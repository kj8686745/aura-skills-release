# AuraQueryTree 查询树

公共子入口 `@fxft/aura-ui/query-tree`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

通过查询回调加载分类树，支持名称搜索、节点自定义和展开折叠。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraQueryTree from '@fxft/aura-ui/query-tree';

const query = async (keyword?: string) => ({ data: [{ id: 1, name: keyword || '示例分类' }] });
</script>

<template>
  <AuraQueryTree :query="query" show-expand />
</template>
```

## Attributes

| 属性 | 默认值 | 说明 | 类型 | 必填 |
| --- | --- | --- | --- | --- |
| query | `undefined` | (keyword?) => PromiseLike<{ data: 节点数组 }>；挂载和搜索 change 时调用 | `(keyword?: string) => PromiseLike<{ data: Record<string, any>[] }>` | 是 |
| props | `{ label: 'name', children: 'children', value: 'id' }` | ElTree 字段映射；node-key 仍固定 id | `Record<string, any>` | 否 |
| placeholder | `''` | 搜索框占位文案 | `string` | 否 |
| loading | `false` | 仅初始化内部状态，后续不监听、不自动复位 | `boolean` | 否 |
| showExpand | `false` | 显示全部展开/折叠菜单 | `boolean` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| nodeClick | 点击树节点，仅发送节点数据 | item: Record<string, any> |
| search | 当前不会触发 | 声明为 ...args: any[] |

## Slots

| 插槽名 | 说明 | 参数 |
| --- | --- | --- |
| default | ElTree 节点实例与节点原数据 | { node, data } |

## Methods

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| getdeptTree | 用当前搜索字重新查询；返回值不包含请求 Promise | 无 | void |

## 注意事项

- query(keyword) 返回 Promise<{ data: 节点数组 }>。挂载时 keyword 为 undefined，输入框 change 时重新查询；清空和 getdeptTree 使用当前关键字。
- 节点键为 id，默认 label=name、children=children，可通过 props 配置映射。nodeClick 发送节点数据，默认插槽接收 { node, data }。
- 查询失败保留原树，并使用公共 message.error 或 ElMessage 提示。没有防抖、缓存或请求竞态隔离。
- getdeptTree 返回 void，不能 await 等待完成。loading 只读取初始值，查询后没有复位；search 事件虽然有声明，但当前不会触发。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraQueryTree: DefineComponent<{
  props?: Record<string, any>;
  placeholder?: string;
  loading?: boolean;
  query: (keyword?: string) => PromiseLike<{ data: Record<string, any>[] }>;
  showExpand?: boolean;
}, {
  getdeptTree: () => void;
}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  search: (...args: any[]) => void;
  nodeClick: (item: Record<string, any>) => void;
}>;

export default AuraQueryTree;
```

API 资料来自 `docs/component/query-tree.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
