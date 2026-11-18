# AuraTreeSelect 树形选择器

公共子入口 `@fxft/aura-ui/tree-select`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

从树形选项中选择节点，支持搜索、字段映射和手风琴模式。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraTreeSelect from '@fxft/aura-ui/tree-select';
import { ref } from 'vue';

const value = ref<string | number | null | undefined>('');
const options = [{ id: 0, label: '根节点' }];
</script>

<template>
  <AuraTreeSelect v-model:value="value" :options="options" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| value | 当前选中的值，支持双向绑定及空值 | `string \| number \| null \| undefined` | `""` | 否 |
| options | 树形数据源 | `any[]` | `[]` | 否 |
| objMap | 字段映射配置 | `{ value: string; label: string; children: string; [key: string]: any }` | `{ value: 'id', label: 'label', children: 'children' }` | 否 |
| accordion | 是否开启手风琴模式 | `boolean` | `false` | 否 |
| placeholder | 输入框占位文本 | `string` | `""` | 否 |

## objMap 字段说明

| 字段 | 说明 | 默认值 |
| ---- | ---- | ------ |
| value | 值字段名 | 'id' |
| label | 显示名称字段名 | 'label' |
| children | 子级字段名 | 'children' |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:value | 选节点或清空；清空顺序见 v-model；外部回显不主动 emit | value: string \| number \| null \| undefined |

## v-model

`v-model:value` 绑定 `string | number | null | undefined`，空字符串、`null`、`undefined` 均清空展示。

## 注意事项

- 使用 v-model:value，0 是有效值。options 异步加载后会同步选中名称；外部更新不会额外发送 update:value。
- objMap 配置节点字段映射，节点值应唯一，label 应为字符串。没有匹配节点时清除旧名称和高亮，保留传入值等待数据匹配。
- 清空可能依次通知 undefined 和空字符串；配置 value-on-clear=null 时第一次为 null。监听方应处理连续空值通知。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraTreeSelect: DefineComponent<{
  value?: string | number | null | undefined;
  options?: any[];
  objMap?: {
    value: string;
    label: string;
    children: string;
    [key: string]: any;
  };
  accordion?: boolean;
  placeholder?: string;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:value': (value: string | number | null | undefined) => void;
}>;

export default AuraTreeSelect;
```

API 资料来自 `docs/component/tree-select.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
