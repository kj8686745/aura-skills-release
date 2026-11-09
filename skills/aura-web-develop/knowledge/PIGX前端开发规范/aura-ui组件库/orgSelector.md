# AuraOrgSelector 组织选择器

公共子入口 `@fxft/aura-ui/org-selector`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

选择用户、部门或角色，支持单选、多选及用户搜索。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraOrgSelector from '@fxft/aura-ui/org-selector';
import { ref } from 'vue';
import type { OrgItem } from '@fxft/aura-ui/org-selector';

const value = ref<OrgItem[]>([]);
// 本地空数据演示；真实接口必须保持该响应结构。
const apiConfig = {
  orgTree: async () => ({ data: { titleDepartments: [], childDepartments: [], roleList: [], employees: [] } }),
  searchUser: async () => ({ data: [] }),
};
</script>

<template>
  <AuraOrgSelector v-model="value" :api-config="apiConfig" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 绑定值，非空时优先于 orgList | `OrgItem[]` | `[]` | 否 |
| orgList | 选中项，可通过 v-model:orgList 绑定 | `OrgItem[]` | `[]` | 否 |
| type | 选择器类型，可选值：user / dept / role / org | `'user' \| 'dept' \| 'role' \| 'org'` | `"user"` | 否 |
| multiple | 是否多选 | `boolean` | `true` | 否 |
| disabled | 禁用新增和标签删除 | `boolean` | `false` | 否 |
| selectSelf | 是否允许选择当前用户 | `boolean` | `true` | 否 |
| currentUserId | 当前用户 ID，未传时读取应用配置 | `string \| number \| null` | `null` | 否 |
| apiConfig | API 配置对象 | `OrgSelectorApiConfig` | `{}` | 否 |
| textConfig | 文本配置对象 | `OrgSelectorTextConfig` | `{}` | 否 |

## API Config

| 属性 | 说明 | 类型 | 是否必填 |
| --- | --- | --- | --- |
| orgTree | 获取组织树的方法；所有选择类型均使用它 | Function(type, parentId) | 未注入 request 时需要 |
| roleList | 当前 role 模式不使用此回调 | Function() | 否 |
| searchUser | 搜索用户的方法，返回 Promise<{ data: OrgItem[] }> | Function(params) | user 搜索且未注入 request 时需要 |

## Text Config

| 属性 | 说明 | 类型 | 默认值 |
| --- | --- | --- | --- |
| dialogTitle | 弹窗标题 | String | '选择' + 类型名称 |
| searchPlaceholder | 搜索框占位文本 | String | '搜索' |
| confirmText | 确认按钮文本 | String | '确认' |
| cancelText | 取消按钮文本 | String | '取消' |
| rootNodeText | 根节点文本 | String | '根节点' |
| nextLevelText | 下一级文本 | String | '下级' |
| selectedText | 已选择文本 | String | '已选' |
| clearText | 清空按钮文本 | String | '清空' |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:modelValue | 确认或已选标签删除时先触发 | value: OrgItem[] |
| update:orgList | 紧随 update:modelValue；取消选择不写回 | value: OrgItem[] |

## v-model

`v-model` 或 `v-model:orgList` 绑定 `OrgItem[]`，空值使用 `[]`；组件依次发送两种更新事件。

## 注意事项

- 优先使用 apiConfig 中的对应回调，否则通过公共 request 查询 GET /admin/dept/org（type、parentDeptId）及 GET /admin/dept/org/user/search（username、pageNum=1、pageSize=30）。
- 组织响应为 { data: { titleDepartments: [], childDepartments: [], roleList: [], employees: [] } }，搜索响应为 { data: OrgItem[] }。条目需提供 type、id、name，可带 avatar、status。
- role 模式从组织接口的 roleList 取值。搜索仅在 user 模式显示，每次输入查询，没有防抖；每次打开从根组织重新加载。
- ID 使用严格比较；禁选本人时，当前用户 ID 与接口 ID 类型应一致。角色、用户的 status===0 禁选，部门使用 status==0。
- 确认输出 { type, id, name, avatar }，取消不写回。非空 modelValue 优先于 orgList，建议只绑定其中一种。
- textConfig 可覆盖文案；禁选本人使用 currentUserId 或公共 orgSelector.getCurrentUserId。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';
import type { OrgItem, OrgSelectorApiConfig, OrgSelectorTextConfig } from '../orgSelector/types';

export type { OrgItem, OrgSelectorApiConfig, OrgSelectorTextConfig } from '../orgSelector/types';

declare const AuraOrgSelector: DefineComponent<{
  modelValue?: OrgItem[];
  orgList?: OrgItem[];
  type?: 'user' | 'dept' | 'role' | 'org';
  multiple?: boolean;
  disabled?: boolean;
  selectSelf?: boolean;
  apiConfig?: OrgSelectorApiConfig;
  textConfig?: OrgSelectorTextConfig;
  currentUserId?: string | number | null;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: OrgItem[]) => void;
  'update:orgList': (value: OrgItem[]) => void;
}>;

export default AuraOrgSelector;
```

### 配套数据类型

```ts
export interface OrgItem {
	id: string | number;
	name: string;
	[key: string]: any;
}

// API 配置接口 - 使用 any 保持灵活性
export interface OrgSelectorApiConfig {
	orgTree?: (type?: any, parentId?: any) => Promise<any>;
	roleList?: () => Promise<any>;
	searchUser?: (params?: any) => Promise<any>;
}

// 文本配置接口
export interface OrgSelectorTextConfig {
	dialogTitle?: string;
	searchPlaceholder?: string;
	rootNodeText?: string;
	nextLevelText?: string;
	selectedText?: string;
	clearText?: string;
	cancelText?: string;
	confirmText?: string;
	[key: string]: any;
}
```

API 资料来自 `docs/component/orgSelector.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
