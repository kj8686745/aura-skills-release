# AuraNameAvatar 名称头像

公共子入口 `@fxft/aura-ui/name-avatar`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

显示图片头像、姓名缩写或数量标记。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraNameAvatar from '@fxft/aura-ui/name-avatar';
</script>

<template>
  <AuraNameAvatar name="张三" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| name | 用户名称 | `string` | `''` | 否 |
| faceUrl | 头像图片URL | `string` | `''` | 否 |
| num | 显示的数字 | `number \| string` | `undefined` | 否 |
| mode | 头像模式 | `string` | `''` | 否 |
| scale | 缩放比例 | `string` | `'1'` | 否 |
| fontColor | 文本颜色 | `string` | `'#fff'` | 否 |
| backgroundColor | 背景颜色 | `string` | `'#3696F2'` | 否 |

## 注意事项

- 数量展示为 +num，姓名取最后两个字符；num=0 且 faceUrl 非空时仍显示图片。
- mode=square 为方形，其他值为圆形。默认头像尺寸 40px，圆形文字为 8px；scale 只改变视觉缩放，不改变布局占位。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { DefineComponent } from 'vue';

declare const AuraNameAvatar: DefineComponent<{
  scale?: string;
  num?: number | string;
  name?: string;
  mode?: string;
  fontColor?: string;
  backgroundColor?: string;
  faceUrl?: string;
}>;

export default AuraNameAvatar;
```

API 资料来自 `docs/component/name-avatar.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
