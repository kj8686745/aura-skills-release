# AuraIconSelector 图标选择器

公共子入口 `@fxft/aura-ui/icon-selector`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

搜索并选择字体图标、Element Plus 图标或本地 SVG 图标。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraIconSelector from '@fxft/aura-ui/icon-selector';
import { ref } from 'vue';

const value = ref('ele-Edit');
</script>

<template>
  <AuraIconSelector v-model="value" />
</template>
```

## 自定义图标来源

在已有公共配置中提供 iconSelector.iconSource 和 iconComponent；也可通过组件属性覆盖来源。

```ts
import * as icons from '@element-plus/icons-vue';
import { createIconfontList } from '@fxft/aura-web-kit/browser/iconfont-list';

app.provide(Symbol.for('@fxft/aura-ui/config'), {
  // 与应用其他已有配置合并。
  iconSelector: { iconSource: createIconfontList(icons) },
});
```

## 属性

| 属性 | 类型 | 默认值 | 必填 | 说明 |
| --- | --- | --- | --- | --- |
| modelValue | `string` | `undefined` | 否 | 图标名称；用于回显，输入搜索文字不会写回 |
| prepend | `string` | `'ele-Pointer'` | 否 | 无已选图标时的前置图标名 |
| placeholder | `string` | `'请输入内容搜索图标或者选择图标'` | 否 | 搜索输入框默认占位文案 |
| size | `'default' \| 'small' \| 'large'` | `'default'` | 否 | 输入框尺寸 |
| title | `string` | `'请选择图标'` | 否 | 弹层标题 |
| disabled | `boolean` | `false` | 否 | 禁用输入、弹层、选择与清空 |
| clearable | `boolean` | `true` | 否 | 是否提供清空入口 |
| emptyDescription | `string` | `'无相关图标'` | 否 | 无图标时的空态描述 |
| iconSource | `ReturnType<typeof createIconfontList>` | `undefined` | 否 | 四个异步来源 ali/ele/awe/local，属性优先于应用配置 |
| textConfig | `Record<string, string>` | `{}` | 否 | 六项文字覆盖，属性优先于应用配置；详见下文 |

## 事件

| 事件 | 参数与时机 |
| --- | --- |
| get | value: string；选择时先发 get，再发 update:modelValue |
| update:modelValue | value: string；选择/清空后的模型通知；搜索、切换分类不触发 |
| clear | value: string（空串）；清空时先发 clear，再发 update:modelValue |

## v-model

`v-model` 绑定图标名称字符串，主动清空输出空字符串；搜索文字不写入模型。

## 注意事项

- 默认从 kit 的 browser/iconfont-list 获取已加载资源，不主动下载字体。字体 CSS 和 SVG symbol 需由应用加载。
- iconSource 可在属性或公共 iconSelector 配置中覆盖，包含 ali/ele/awe/local 四个 Promise 回调；属性优先。分别返回字体 class、ele-*、不带 "fa " 前缀的名称、local-*。
- 渲染优先使用公共 iconComponent，默认使用 SvgIcon；textConfig 属性优先于公共配置。
- 外部 modelValue 会回显并切换分类；搜索不写入绑定值，选择后弹层保持打开。自定义图标名称应符合相应前缀规则。
- 每次打开会刷新字体和本地 SVG 列表；弹层打开期间，已加载字体资源变化也会刷新。来源加载失败时显示空列表。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';
import type { createIconfontList } from '@fxft/aura-web-kit/browser/iconfont-list';

declare const AuraIconSelector: DefineComponent<{
  modelValue?: string;
  prepend?: string;
  placeholder?: string;
  size?: 'default' | 'small' | 'large';
  title?: string;
  disabled?: boolean;
  clearable?: boolean;
  emptyDescription?: string;
  iconSource?: ReturnType<typeof createIconfontList>;
  textConfig?: {
    clearText?: string;
    aliLabel?: string;
    eleLabel?: string;
    aweLabel?: string;
    localLabel?: string;
    searchPlaceholder?: string;
  };
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: string) => void;
  get: (value: string) => void;
  clear: (value: string) => void;
}>;

export default AuraIconSelector;
```

API 资料来自 `docs/component/icon-selector.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
