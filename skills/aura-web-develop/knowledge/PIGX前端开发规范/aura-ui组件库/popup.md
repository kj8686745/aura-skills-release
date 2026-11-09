# AuraPopup 弹窗

公共子入口 `@fxft/aura-ui/popup`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

带触发区域、确认和取消按钮的弹窗，支持异步确认。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraPopup from '@fxft/aura-ui/popup';
</script>

<template>
  <AuraPopup title="确认操作" content="确认后由业务保存"><template #trigger><button>打开</button></template></AuraPopup>
</template>
```

## 实例方法

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| open | disabled 时直接返回，否则打开并发 open | 无 | void |
| close | 关闭并在 nextTick 发 close；不返回可等待关闭动画的 Promise | 无 | void |
| handleEvent | 触发对应确认或取消事件，并按 async 规则关闭 | type: 'confirm' \| 'cancel' | void |

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| title | 弹窗标题 | `string` | `''` | 否 |
| content | 弹窗内容 | `string` | `''` | 否 |
| width | 弹窗宽度 | `string` | `'400px'` | 否 |
| disabled | 是否禁用弹窗 | `boolean` | `false` | 否 |
| async | 是否开启异步关闭 | `boolean` | `false` | 否 |
| clickModalClose | 点击遮罩层是否关闭弹窗 | `boolean` | `false` | 否 |
| center | 是否居中布局 | `boolean` | `false` | 否 |
| customClass | 自定义弹窗的类名 | `string` | `''` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| confirm | 点击确认先触发；async=false 后调用 close() | 无 |
| cancel | 点击取消先触发，然后调用 close()，不受 async 限制 | 无 |
| open | open() 未被 disabled 拦截时，在 visible=true 前同步触发 | 无 |
| close | close() 的 nextTick 触发；ElDialog closed 再调用 close，单次关闭可能重复通知 | 无 |

## Slots

| 插槽名 | 说明 | 参数 |
| --- | --- | --- |
| trigger | 点击后调用 open 的触发区 | 无 |
| default | 弹窗主体，替代 content；无 header/footer 对外插槽 | 无 |

## 注意事项

- 通过 trigger 插槽或 ref.open() 打开，通过 ref.close() 关闭；disabled 时 open 不生效。
- async=true 时确认不会自动关闭，业务操作成功后需主动 close；取消仍会关闭。
- 不提供 v-model:visible。ref 可访问 visible 和 handleEvent；内容子组件可注入 visible 状态。
- close 在部分关闭路径中可能重复通知，业务关闭处理应可重复执行。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraPopup: DefineComponent<{
  title?: string;
  content?: string;
  width?: string;
  disabled?: boolean;
  async?: boolean;
  clickModalClose?: boolean;
  center?: boolean;
  customClass?: string;
}, {
  visible: boolean;
  handleEvent: (type: 'confirm' | 'cancel') => void;
  open: () => void;
  close: () => void;
}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  confirm: () => void;
  cancel: () => void;
  close: () => void;
  open: () => void;
}>;

export default AuraPopup;
```

API 资料来自 `docs/component/popup.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
