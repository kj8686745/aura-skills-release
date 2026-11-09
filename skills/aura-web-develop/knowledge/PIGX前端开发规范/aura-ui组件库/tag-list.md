# AuraTagList 标签列表

公共子入口 `@fxft/aura-ui/tag-list`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

展示和编辑字符串标签数组，支持新增与删除。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraTagList from '@fxft/aura-ui/tag-list';
import { ref } from 'vue';

const value = ref(['标签']);
</script>

<template>
  <AuraTagList v-model="value" closable :disable-add="false" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 标签数组 | `string[]` | `[]` | 否 |
| buttonText | 新增按钮文案（仅在可新增时显示） | `string` | `'+ New Tag'` | 否 |
| tagType | 标签类型：`primary` / `success` / `info` / `warning` / `danger` | `'primary' \| 'success' \| 'info' \| 'warning' \| 'danger'` | `'primary'` | 否 |
| closable | 显式属性 → tagList.closable → true | `boolean` | `undefined`（最终默认 true） | 否 |
| disableAdd | 显式属性 → tagList.disableAdd → false；true 隐藏新增入口 | `boolean` | `undefined`（最终默认 false） | 否 |

## Events

| 事件名 | 说明 | 回调参数 |
| --- | --- | --- |
| update:modelValue | 新增确认或移除标签；新增不去重 | tags: string[] |

## v-model

`v-model` 绑定 `string[]`，空值使用 `[]`。

## 注意事项

- 默认允许新增和删除；只读展示需同时设置 closable=false、disableAdd=true。
- 允许重复标签，不自动校验或去重；绑定值使用数组，空值为 []。
- 公共 tagList 配置可调整默认行为，组件显式属性优先。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraTagList: DefineComponent<{
  modelValue?: string[];
  buttonText?: string;
  tagType?: 'primary' | 'success' | 'info' | 'warning' | 'danger';
  closable?: boolean;
  disableAdd?: boolean;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (tags: string[]) => void;
}>;

export default AuraTagList;
```

API 资料来自 `docs/component/tag-list.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
