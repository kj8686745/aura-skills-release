# AuraBusinessIconPicker 业务图片图标选择器

公共子入口 `@fxft/aura-ui/business-icon-picker`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

按分组搜索、分页选择后台维护的图片图标，可同时绑定图标编码和图片地址。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraBusinessIconPicker from '@fxft/aura-ui/business-icon-picker';
import { ref } from 'vue';

const value = ref('');
const iconUrl = ref('');
// 先按公共接入注入真实 request，否则没有远程图标可选。
</script>

<template>
  <AuraBusinessIconPicker v-model="value" v-model:iconUrl="iconUrl" />
</template>
```

## 接口

以下接口均使用 `GET`。分组与列表返回 `{ data: [] }`，分页返回 `{ data: { records, total } }`。

| 接口 | 用途 | 参数 |
| --- | --- | --- |
| `/admin/sys-icon/groups` | 打开时加载分组，非空结果缓存到当前实例 | 无 |
| `/admin/sys-icon/list` | 回显项缺少分组时查找对应图标 | 无 |
| `/admin/sys-icon/page` | 搜索、分组与分页 | current、size、keyword、groupCode；空筛选值为 undefined |

## 属性

| 属性 | 类型 | 默认值 | 说明 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | `string` | `''` | 保存字段的字符串值 | 否 |
| valueField | `'id' \| 'code' \| 'fileUrl'` | `'code'` | 选择时从图标对象提取的字段 | 否 |
| iconUrl | `string` | `''` | 回显图片 URL，可通过 v-model:iconUrl 接收更新 | 否 |
| selectedIcon | `SysIconInfo` | `undefined` | 外部回显对象，需由调用方保持与 modelValue 一致 | 否 |
| defaultTab | `string` | `'all'` | 默认分组；打开时未知分组回退 all | 否 |
| placeholder | `string` | `undefined` | 未传时显示当前语言的占位文字；显式空串保持为空 | 否 |
| disabled | `boolean` | `false` | 禁止打开、请求和选择，并关闭已有弹层 | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:modelValue | 选中图标后先输出保存字段 | value: string |
| update:iconUrl | 随后输出 fileUrl 或空串 | value: string |
| change | 最后输出对象，再关闭弹层 | value: SysIconInfo |

## v-model

`v-model` 绑定图标编码，`v-model:iconUrl` 绑定图片地址，均为 `string`，默认空字符串。

## 注意事项

- 通过公共配置提供 `request`，可选提供 `getFileUrl`。
- 分组编码支持 itemValue/value/code/groupCode，名称支持 label/itemLabel/name/itemValue。SysIconInfo 的 id、name、code、groupCode、fileId、fileUrl、sortOrder、createTime 均为可选字段。
- 回显优先级：当前页匹配项 → 实例缓存 → selectedIcon → iconUrl。selectedIcon 应与绑定值一致。
- 每次打开回到第一页；切换分组、搜索或页容量也会重置页码。选择后关闭弹层，分页失败保留原列表。
- 没有清空按钮；需要清空时同时重置 modelValue 和 iconUrl。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

export interface SysIconInfo {
  id?: string;
  name?: string;
  code?: string;
  groupCode?: string;
  fileId?: string;
  fileUrl?: string;
  sortOrder?: number;
  createTime?: string;
}

declare const AuraBusinessIconPicker: DefineComponent<{
  modelValue?: string;
  valueField?: 'id' | 'code' | 'fileUrl';
  iconUrl?: string;
  selectedIcon?: SysIconInfo;
  defaultTab?: string;
  placeholder?: string;
  disabled?: boolean;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: string) => void;
  'update:iconUrl': (value: string) => void;
  change: (value: SysIconInfo) => void;
}>;

export default AuraBusinessIconPicker;
```

API 资料来自 `docs/component/business-icon-picker.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
