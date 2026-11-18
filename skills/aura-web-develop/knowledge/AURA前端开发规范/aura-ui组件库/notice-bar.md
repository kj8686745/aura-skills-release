# AuraNoticeBar 通知栏

公共子入口 `@fxft/aura-ui/notice-bar`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

展示通知文本，支持水平滚动、关闭和链接按钮。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraNoticeBar from '@fxft/aura-ui/notice-bar';
</script>

<template>
  <AuraNoticeBar mode="closeable" right-icon="ele-CloseBold" text="系统通知" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| mode | 通知栏模式，可选值为 `closeable`（可关闭）、`link`（链接） | `string` | `''` | 否 |
| text | 通知文本内容 | `string` | `''` | 否 |
| color | 通知文本颜色 | `string` | `'var(--el-color-warning)'` | 否 |
| background | 通知背景色 | `string` | `'var(--el-color-warning-light-9)'` | 否 |
| size | 字体大小，单位px | `number \| string` | `14` | 否 |
| height | 通知栏高度，单位px | `number` | `40` | 否 |
| delay | 动画延迟时间 (s) | `number` | `1` | 否 |
| speed | 滚动速率 (px/s) | `number` | `100` | 否 |
| scrollable | 为 true 时显示默认插槽并关闭文本水平动画；垂直轮播由插槽内容实现 | `boolean` | `false` | 否 |
| leftIcon | 自定义左侧图标类名 | `string` | `''` | 否 |
| rightIcon | 自定义右侧图标名称（SvgIcon 组件使用） | `string` | `''` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| close | mode=closeable 且点击显式 rightIcon，先隐藏再 emit | 无 |
| link | mode=link 且点击显式 rightIcon；不执行跳转 | 无 |

## Slots

| 名称 | 说明 | 参数 |
| --- | --- | --- |
| default | 仅 scrollable=true 渲染，自行实现轮播内容 | 无 |

## 注意事项

- 关闭或链接操作都需要显式设置 rightIcon。mode=closeable 时点击右图标隐藏组件并发送 close；mode=link 时发送 link，由调用方处理跳转。
- 左图标按字体 class 渲染，右图标默认使用 SvgIcon，可通过公共 iconComponent 覆盖。
- 水平动画只在挂载时测量尺寸。文字、容器、scrollable 或滚动配置改变后，需要通过 key 重建以重新测量。
- speed 应大于 0，delay 应不小于 0；size 的字符串值表示不带单位的像素数。scrollable=true 的内容由默认插槽提供。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraNoticeBar: DefineComponent<{
  mode?: string;
  text?: string;
  color?: string;
  background?: string;
  size?: number | string;
  height?: number;
  delay?: number;
  speed?: number;
  scrollable?: boolean;
  leftIcon?: string;
  rightIcon?: string;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  close: () => void;
  link: () => void;
}>;

export default AuraNoticeBar;
```

API 资料来自 `docs/component/notice-bar.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
