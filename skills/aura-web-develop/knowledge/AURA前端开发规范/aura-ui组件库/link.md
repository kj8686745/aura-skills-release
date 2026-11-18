# AuraLinkPicker 链接选择器

公共子入口 `@fxft/aura-ui/link-picker`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

选择应用页面或填写外部链接，确认后返回链接对象。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraLinkPicker from '@fxft/aura-ui/link-picker';
import { ref } from 'vue';

const value = ref();
const pages = [{ path: '/REPLACE_WITH_APP_PAGE', name: '应用页面', type: 'shop' }];
</script>

<template>
  <AuraLinkPicker v-model="value" :pages="pages" />
</template>
```

## Link 类型定义

```typescript
interface Link {
  path: string;        // 链接路径
  name?: string;       // 链接名称
  type: string;        // 链接类型：'shop' 或 'custom'
  query?: Record<string, any>; // 查询参数
}

enum LinkTypeEnum {
  SHOP_PAGES = 'shop',    // 商城页面
  CUSTOM_LINK = 'custom'  // 自定义链接
}
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 绑定值 | `Partial<Link> \| null` | `undefined` | 否 |
| disabled | 是否禁用 | `boolean` | `false` | 否 |
| pages | 页面列表，显式传入时优先于应用配置；传空数组可隐藏所有页面选项 | `Link[]` | `undefined` | 否 |
| textConfig | 标题、占位符、菜单及提示文案，支持应用配置和属性覆盖 | `Record<string, string>` | `{}` | 否 |

## Events

| 事件名 | 说明 | 回调参数 |
| --- | --- | --- |
| update:modelValue | Popup 确认时输出当前草稿；编辑/取消不写回 | value: Link（实际草稿可能不完整） |

## v-model

`v-model` 绑定 `Partial<Link> | null`，允许 `undefined` 或 `{}` 表示未选择。

## 注意事项

- 通过 pages 属性或公共 linkPicker.pages 提供应用页面；显式属性优先。LinkTypeEnum 和 Link 从 @fxft/aura-ui/link-picker 显式导入。
- textConfig 支持 title、placeholder、pagesTitle、customTitle、customPlaceholder、customTip，属性优先于公共配置。
- 取消不更新模型，也不清空草稿；外部清空为 {}、null 或 undefined 不会重置内部草稿。确认可能返回不完整对象，保存前需校验。
- 自定义链接输出使用 path，只读展示却读取 query.url；仅提供 path 时展示可能为空。组件不校验 URL，也不执行跳转。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';
import type { Link } from '../link/type';

export type { Link } from '../link/type';
export { LinkTypeEnum } from '../link/type';

declare const AuraLinkPicker: DefineComponent<{
  modelValue?: Partial<Link> | null;
  disabled?: boolean;
  pages?: Link[];
  textConfig?: {
    title?: string;
    placeholder?: string;
    pagesTitle?: string;
    customTitle?: string;
    customPlaceholder?: string;
    customTip?: string;
  };
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: Link) => void;
}>;

export default AuraLinkPicker;
```

### 配套数据类型

```ts
export declare enum LinkTypeEnum {
  SHOP_PAGES = 'shop',
  CUSTOM_LINK = 'custom',
}

export interface Link {
  path: string;
  name?: string;
  type: string;
  query?: Record<string, any>;
}
```

API 资料来自 `docs/component/link.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
