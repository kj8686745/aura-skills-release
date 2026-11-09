# AuraFormTable 表单表格

公共子入口 `@fxft/aura-ui/form-table`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

在表格中编辑表单数组，支持新增、删除和拖拽排序。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraFormTable from '@fxft/aura-ui/form-table';
import { ref } from 'vue';
import { ElTableColumn } from 'element-plus';

const value = ref<Record<string, any>[]>([{ name: '示例' }]);
</script>

<template>
  <AuraFormTable v-model="value" :add-template="{ name: '' }"><ElTableColumn prop="name" label="名称" /></AuraFormTable>
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 表格数据，支持 v-model 双向绑定 | `Record<string, any>[]` | `[]` | 否 |
| addTemplate | 新增行的模板对象，新增行时会深拷贝此对象 | `Record<string, any>` | `{}` | 否 |
| placeholder | 无数据时的提示语 | `string` | `'暂无数据'` | 否 |
| dragSort | 是否启用拖拽排序功能 | `boolean` | `false` | 否 |
| hideAdd | 是否隐藏新增按钮 | `boolean` | `false` | 否 |
| hideDelete | 是否隐藏删除按钮 | `boolean` | `false` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:modelValue | 数据回显、编辑、增删及排序时触发；拖拽先发送 []，再发送排序结果 | data: Record<string, any>[] |
| delete | rowDel 删除时触发，早于模型更新；deleteRow 不触发 | row: Record<string, any> |

## Slots

| 插槽名 | 说明 | 参数 |
| --- | --- | --- |
| default | 宿主导入的 ElTableColumn；单元格 scope 由列本身提供 | 无 |

## Methods

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| pushRow | 传对象直接使用；未传时 JSON 复制 addTemplate | row?: Record<string, any> | void |
| deleteRow | 按索引删除，不触发 delete；请传入合法的非负索引 | index: number | void |
| rowAdd | JSON 复制 addTemplate 后追加 | 无 | void |
| rowDel | 按 index 删除并同步发 delete(row) | row: Record<string, any>, index: number | void |
| rowDrop | 挂载后初始化/重建 Sortable；先销毁旧实例，要求已存在表体 | 无 | void |

## v-model

`v-model` 绑定行对象数组，空值使用 `[]`。

## 注意事项

- 列和输入控件由默认插槽提供。删除按钮默认位于序号列；公共 formTable.deleteInIndex=false 可改为独立操作列。
- 行对象与调用方共享，单元格编辑直接修改行对象。拖拽排序会先输出 []，再在 nextTick 回填，避免把每次模型更新直接作为保存操作。
- dragSort 在挂载时初始化；需要重新初始化排序时调用 rowDrop。隐藏按钮不会禁止通过 ref 新增或删除。
- rowAdd 和无参数 pushRow 通过 JSON 序列化复制 addTemplate；pushRow(row) 直接使用传入对象。rowDel 会发送 delete，deleteRow 不发送。
- ref.data 为当前表格数据；未设置 addTemplate 时新增空对象。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraFormTable: DefineComponent<{
  modelValue?: Record<string, any>[];
  addTemplate?: Record<string, any>;
  placeholder?: string;
  dragSort?: boolean;
  hideAdd?: boolean;
  hideDelete?: boolean;
}, {
  data: Record<string, any>[];
  pushRow: (row?: Record<string, any>) => void;
  deleteRow: (index: number) => void;
  rowAdd: () => void;
  rowDel: (row: Record<string, any>, index: number) => void;
  rowDrop: () => void;
}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (data: Record<string, any>[]) => void;
  delete: (row: Record<string, any>) => void;
}>;

export default AuraFormTable;
```

API 资料来自 `docs/component/form-table.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
