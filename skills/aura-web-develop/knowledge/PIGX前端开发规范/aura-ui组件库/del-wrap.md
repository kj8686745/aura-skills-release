# AuraDelWrap 删除包装器

公共子入口 `@fxft/aura-ui/del-wrap`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

为卡片、图片等内容添加悬停显示的删除按钮。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraDelWrap from '@fxft/aura-ui/del-wrap';
</script>

<template>
  <AuraDelWrap @close="() => console.log('请在这里更新业务列表')">内容</AuraDelWrap>
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| showClose | 是否显示删除按钮 | `boolean` | `true` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| close | 点击关闭区域，停止原点击冒泡；不删除数据 | 无 |

## Slots

| 插槽名 | 说明 | 参数 |
| --- | --- | --- |
| default | 包裹内容 | 无 |

## Methods

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| handleClose | 触发 close 事件，由调用方处理删除 | 无 | void |

## 注意事项

- 点击删除按钮会阻止事件冒泡，并触发无参数 close。组件只发送删除通知，由调用方移除数据。
- showClose=false 时不渲染删除按钮；class 等属性作用于包装器根节点。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraDelWrap: DefineComponent<{
  showClose?: boolean;
}, { handleClose: () => void }, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  close: () => void;
}>;

export default AuraDelWrap;
```

API 资料来自 `docs/component/del-wrap.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
