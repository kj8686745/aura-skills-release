# AuraOrgTreeView 组织管理树

公共子入口 `@fxft/aura-ui/org-tree-view`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

组织管理树，支持组织查询、新增、编辑、删除和租户根节点展示。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraOrgTreeView from '@fxft/aura-ui/org-tree-view';
import { defineComponent } from 'vue';

const api = { treeData: async () => ({ data: [] }), delete: async () => ({ data: null }) };
// 演示表单适配器；真实业务应实现编辑弹窗并发送 refresh。
const formComponent = defineComponent({
  setup(_, { expose }) {
    expose({ openDialog: (...args: unknown[]) => console.log('由业务实现表单', args) });
    return () => null;
  },
});
</script>

<template>
  <div style="height: 400px"><AuraOrgTreeView :api="api" :form-component="formComponent" /></div>
</template>
```

## 租户与应用配置

在布局 setup 中提供响应式会话、租户查询和主题回调。示例中的 Store、消息服务和 API 由应用提供。

```ts
import { provideAuraUiConfig } from '@fxft/aura-ui/config';
import { useMessage, useMessageBox } from '/@/config/aura/index';

const message = useMessage();
const messageBox = useMessageBox();

// 在布局 setup 中注入一次，后代机构树自动读取。
provideAuraUiConfig({
  message,
  confirm: (text: string) => messageBox.confirm(text),
  orgTreeView: {
    getCurrentTenant: () => {
      const { time, tenantId, tenantName, user } = userInfoStore.userInfos;
      if (!time || tenantId === undefined || tenantId === null || tenantId === '') return undefined;
      return { id: tenantId, name: tenantName, userId: user.userId };
    },
    getTenant,
    isDark: () => themeConfig.themeConfig.isDark,
  },
});
```

## Attributes

| 属性 | 说明 | 类型 | 必填 | 默认值 |
| --- | --- | --- | --- | --- |
| api | 必需 treeData(params?)、delete(id)；可选 getTenant(tenantId)，返回 { data } | `OrgTreeViewAPI` | 是 | `undefined` |
| formComponent | 业务表单，实例需暴露 openDialog；发送 refresh 时重新查询 | `Component` | 是 | `undefined` |
| config | 字段映射、根节点、布局、文本、extraParams/checkNode；menus 当前未使用 | `OrgTreeViewConfig` | 否 | `{}` |

## config 配置

| config 字段 | 类型 | 默认值 | 约束 |
| --- | --- | --- | --- |
| props | `{ id?, pid?, label?, expand?, children? }`，各值 string | id/id、pid/parentId、label/name、expand/expand、children/children | 与默认映射合并；内部构建根和 children、增删改仍使用部分固定字段 |
| menus | `{ name: string; command: string }[]` | 可选，当前未使用 | 不会覆盖当前新增/编辑/删除菜单 |
| rootNode | `{ id: string; name: string }` | `{ id: '0', name: '根节点' }` | 字段分别合并；显式 name 优先于全局租户名称，页面 api.getTenant 仍可覆盖 |
| defaultExpandLevel | number | 2 | 透传 vue3-tree-org |
| horizontal | boolean | false | 水平布局 |
| collapsable | boolean | false | 仅初始化内部折叠状态；后续通过 handleExpand 切换 |
| onlyOneNode | boolean | false | 透传 vue3-tree-org |
| cloneNodeDrag | boolean | true | 不提供拖拽持久化接口 |
| i18nKeys | `{ addNodeText?, editNodeText?, delNodeText?, tenantNodeErrorText? }` | 前三项走应用翻译或中文，根节点禁止提示默认中文 | 值为直接文案，不是再调用 $t 的 key |
| extraParams | Record<string, any> | undefined | 查询 getOrgData 显式参数优先；新增读取 stripLineId/currentNodeId |
| checkNode | `(node: OrgTreeNode) => boolean` | 默认检查 node.id 不等于 rootNode.id | 只在编辑/删除时调用，可覆盖根节点保护 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| node-click | 左键节点点击先派发 contextmenu，再发送原鼠标事件，不是节点对象 | event: MouseEvent |
| refresh | 删除成功并重新查询后触发；业务表单 refresh 只重查，不转发 | 无 |

## Methods

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| getOrgData | 加载部门树，不等待租户名称补查；会话未就绪时不查询，请求失败时 reject | params?: any | `Promise<void>` |
| handleExpand | 切换内部 collapsable，非逐个设置 expand 字段 | 无 | `Promise<void>` |
| filter | 挂载后调用底层 filter，匹配 label/name 忽略大小写 | name: string | void |

## 注意事项

- api.treeData(params) 返回 { data: OrgTreeNode[] }；api.delete(id) 成功后重新查询，失败应 reject。组件不判断删除响应的业务 code。节点需提供 id、name，可带 parentId、label、expand、children。
- formComponent 需暴露 openDialog("add", undefined, stripLineId, parentId) 和 openDialog("edit", id)。表单发送 refresh 时只重新查询；组件自己的 refresh 在删除成功并重查后触发。
- 公共 getCurrentTenant 应读取响应式会话状态，返回 { id, name, userId? }；返回 undefined 时等待会话就绪。租户或用户变化会重新加载部门树，名称变化只更新显示。
- 根名称优先级：页面 api.getTenant → 显式 config.rootNode.name → 当前租户名称 → 公共 getTenant 补查 → 默认根名称。补查失败不阻塞树加载。旧 getTenantId + api.getTenant 接入仍可用。
- getOrgData 的显式参数优先于 extraParams。默认禁止编辑、删除根节点，可通过 checkNode 覆盖；i18nKeys 填直接显示文案。
- config.menus 当前不生效，字段映射也未覆盖全部内部固定字段；拖拽不提供保存接口。依赖浏览器环境，SSR 应用在客户端加载。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { Component, ComponentOptionsMixin, DefineComponent } from 'vue';
import type { OrgTreeViewAPI, OrgTreeViewConfig } from './types.js';

export type * from './types.js';

declare const AuraOrgTreeView: DefineComponent<{
  api: OrgTreeViewAPI;
  formComponent: Component;
  config?: OrgTreeViewConfig;
}, {
  getOrgData: (params?: any) => Promise<void>;
  handleExpand: () => Promise<void>;
  filter: (name: string) => void;
}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'node-click': (event: MouseEvent) => void;
  refresh: () => void;
}>;

export default AuraOrgTreeView;
```

### 配套数据类型

```ts
export interface OrgTreeViewProps {
	id?: string;
	pid?: string;
	label?: string;
	expand?: string;
	children?: string;
}

export interface OrgTreeViewMenu {
	name: string;
	command: string;
}

export interface OrgTreeViewAPI {
	treeData: (params?: any) => Promise<any>;
	delete(id: string | number): Promise<any>;
	getTenant?: (tenantId: string) => Promise<any>;
}

export interface OrgTreeViewI18nKeys {
	addNodeText: string;
	editNodeText: string;
	delNodeText: string;
	tenantNodeErrorText?: string;
}

export interface OrgTreeViewRootNode {
	id: string;
	name: string;
}

export interface OrgTreeViewConfig {
	props?: OrgTreeViewProps;
	menus?: OrgTreeViewMenu[];
	rootNode?: OrgTreeViewRootNode;
	defaultExpandLevel?: number;
	horizontal?: boolean;
	collapsable?: boolean;
	onlyOneNode?: boolean;
	cloneNodeDrag?: boolean;
	i18nKeys?: Partial<OrgTreeViewI18nKeys>;
	extraParams?: Record<string, any>;
	checkNode?: (node: OrgTreeNode) => boolean;
}

export interface OrgTreeNode {
	id: string | number;
	parentId?: string | number;
	name: string;
	label?: string;
	expand?: boolean;
	children?: OrgTreeNode[];
	[key: string]: any;
}
```

API 资料来自 `docs/component/org-tree-view.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
