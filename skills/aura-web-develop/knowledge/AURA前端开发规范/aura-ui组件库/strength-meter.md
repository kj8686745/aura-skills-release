# AuraStrengthMeter 密码强度检测器

公共子入口 `@fxft/aura-ui/strength-meter`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

输入密码并展示强度评分，支持监听评分变化。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraStrengthMeter from '@fxft/aura-ui/strength-meter';
import { ref } from 'vue';

const value = ref('');
</script>

<template>
  <AuraStrengthMeter v-model:value="value" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| value | 密码值，支持 v-model:value 双向绑定 | `string` | `''` | 否 |
| showInput | 当前不生效，输入框始终显示 | `boolean` | `true` | 否 |
| disabled | 停止评分并清空强度条；保持既有行为，不禁用输入框 | `boolean` | `false` | 否 |
| height | 透传到输入框的 height 属性 | `number \| string` | `''` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:value | 输入值变化或外部回显时触发，早于 change | value: string |
| change | 紧随 update:value；并非只在失焦触发 | value: string |
| score | 评分重新计算时触发；disabled 时不触发，与值更新事件无固定先后顺序 | score: '0' \| '1' \| '2' \| '3' \| -1 |

## Slots

| 插槽名 | 说明 | 参数 |
| --- | --- | --- |
| ElInput 的动态插槽 | 支持 prefix、suffix、prepend、append 等插槽 | ElInput 传出的原参数 data；无参数时 {} |

## v-model

`v-model:value` 绑定密码字符串，空值使用 `''`。

## 注意事项

- 使用 v-model:value。disabled 只停止评分并清空强度条，不禁用输入；showInput 当前不会隐藏输入框。
- 评分字符为数字、英文字母及 !@#$%^&.*，长度 6～100 位。未输入为数字 -1；非空评分为字符串 "0"～"3"：不符合规则、弱、中、强。
- 强度评分用于提示，不替代业务密码校验。输入框属性和动态插槽可透传给 ElInput。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraStrengthMeter: DefineComponent<{
  value?: string;
  modelValue?: string;
  'onUpdate:modelValue'?: (value: string) => void;
  placeholder?: string;
  autocomplete?: string;
  maxlength?: number | string;
  minlength?: number | string;
  maxLength?: number | string;
  minLength?: number | string;
  showInput?: boolean;
  disabled?: boolean;
  height?: number | string;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:value': (value: string) => void;
  change: (value: string) => void;
  score: (score: string | -1) => void;
}>;

export default AuraStrengthMeter;
```

API 资料来自 `docs/component/strength-meter.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
