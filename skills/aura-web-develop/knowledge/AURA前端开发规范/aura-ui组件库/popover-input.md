# AuraPopoverInput 弹出输入框

公共子入口 `@fxft/aura-ui/popover-input`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

在触发元素旁弹出文本输入框或选择框。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraPopoverInput from '@fxft/aura-ui/popover-input';
import { ref } from 'vue';

const value = ref();
</script>

<template>
  <AuraPopoverInput v-model="value"><button>输入新值</button></AuraPopoverInput>
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 可选值 | 默认值 | 必填 |
| --- | --- | --- | --- | --- | --- |
| modelValue | 兼容输入属性，实际不读取；输入结果通过事件输出 | `string` | — | `undefined` | 否 |
| type | 输入框类型 | `string` | text/textarea 等 ElInput 类型；select | `'text'` | 否 |
| width | 弹出框的宽度 | `number \| string` | — | `'300px'` | 否 |
| placeholder | 输入框的占位符 | `string` | — | `undefined` | 否 |
| disabled | 是否禁用 | `boolean` | — | `false` | 否 |
| options | select 模式选项：{ label, value }；value 原样输出 | `{ label: string; value: any }[]` | — | `[]` | 否 |
| size | 组件尺寸 | `'default' \| 'small' \| 'large'` | default/small/large | `'default'` | 否 |
| limit | 当前不生效，限制长度请使用 maxlength | `number` | — | `200` | 否 |
| maxlength | 输入框最大长度 | `number` | — | `20` | 否 |
| showLimit | 是否显示字符计数 | `boolean` | — | `false` | 否 |
| teleported | 是否将弹出框插入至 body 元素上 | `boolean` | — | `true` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| confirm | 确认时先关闭弹层，再同步 confirm，随后 update:modelValue | value: any |
| update:modelValue | 初始化、打开清空、输入及确认时触发；相同值也可能重复通知 | value: any（含 undefined） |

## Slots

| 插槽名 | 说明 | 参数 |
| --- | --- | --- |
| default | 触发区域 | 无 |

## v-model

`v-model` 接收输入值：文本模式为字符串，选择模式为选项原值；初始化还会输出 `undefined`。

## 注意事项

- 创建时会发送 update:modelValue(undefined)，每次打开都会清空输入，不回填 modelValue 或 value。
- 输入时更新模型，取消不会恢复旧值；确认先发送 confirm，再发送 update:modelValue。
- 文本输出字符串，选择框输出选项原值。限制长度使用 maxlength，limit 当前不生效。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraPopoverInput: DefineComponent<{
  modelValue?: string;
  type?: string;
  width?: number | string;
  placeholder?: string;
  disabled?: boolean;
  options?: any[];
  size?: 'default' | 'small' | 'large';
  limit?: number;
  maxlength?: number;
  showLimit?: boolean;
  teleported?: boolean;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  confirm: (value: any) => void;
  'update:modelValue': (value: any) => void;
}>;

export default AuraPopoverInput;
```

API 资料来自 `docs/component/popover-input.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
