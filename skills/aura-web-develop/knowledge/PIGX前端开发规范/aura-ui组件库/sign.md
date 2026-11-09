# AuraSign 签名

公共子入口 `@fxft/aura-ui/sign`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

使用鼠标或触摸手写签名，生成 PNG data URL。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraSign from '@fxft/aura-ui/sign';
import { ref } from 'vue';

const value = ref('');
</script>

<template>
  <AuraSign v-model="value" :width="300" :height="150" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| width | 签名画布宽度（像素） | `number` | `300` | 否 |
| height | 签名画布高度（像素） | `number` | `150` | 否 |
| lineWidth | 签名线条粗细（像素） | `number` | `2` | 否 |
| lineColor | 签名线条颜色 | `string` | `'#000000'` | 否 |
| bgColor | 画布背景颜色，空字符串表示透明 | `string` | `''` | 否 |
| isCrop | 是否裁剪签名区域（当前未实现） | `boolean` | `false` | 否 |
| isClearBgColor | 重置时是否清除背景颜色 | `boolean` | `true` | 否 |
| modelValue | 签名结果的 base64 数据（v-model） | `string` | `''` | 否 |
| disabled | 是否禁用签名功能 | `boolean` | `false` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:modelValue | 确认签名成功输出 PNG；清空/重新签名按钮输出空串；ref 方法不触发 | value: string |

## Expose

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| reset | 只清空画布，不更新模型；isClearBgColor 时清除 CSS 背景 | 无 | void |
| generate | PNG data URL；未绘制/Canvas 不可用则 reject；不更新模型、不裁剪 | 无 | `Promise<string>` |

## v-model

`v-model` 绑定 PNG data URL 或回显图片地址；空字符串进入绘制状态。

## 注意事项

- width、height 决定画布尺寸，不会随外层容器自动铺满；Grid 容器中可用 justify-self: start 避免额外拉伸。
- generate 返回 PNG data URL，未签名时拒绝 Promise；reset 清空画布。通过 ref 调用这两个方法不会更新模型，按钮确认或重签才会更新。
- isCrop 当前未实现；窗口缩放会清空画布，disabled 不会禁用已回显签名的重签按钮。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraSign: DefineComponent<{
  width?: number;
  height?: number;
  lineWidth?: number;
  lineColor?: string;
  bgColor?: string;
  isCrop?: boolean;
  isClearBgColor?: boolean;
  modelValue?: string;
  disabled?: boolean;
}, {
  reset: () => void;
  generate: () => Promise<string>;
}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: string) => void;
}>;

export default AuraSign;
```

API 资料来自 `docs/component/sign.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
