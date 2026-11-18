# AuraChinaArea 中国地区选择器

公共子入口 `@fxft/aura-ui/china-area`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

选择行政区，绑定值为逗号分隔的区域编码字符串。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraChinaArea from '@fxft/aura-ui/china-area';
import { ref } from 'vue';

const value = ref('');
const options = [{ name: '示例地区', adcode: 'EXAMPLE_CODE' }];
</script>

<template>
  <AuraChinaArea v-model="value" :options="options" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 逗号分隔的编码路径，与选项中的字符串 adcode 对应 | `string` | `undefined` | 否 |
| options | name / adcode / children 结构；提供后使用数据驱动模式 | `CascaderOption[]` | `undefined` | 否 |
| type | 自动请求时传给行政区接口的层级参数，业务现有用法为 1～4 | `number` | `4` | 否 |
| disabled | 是否禁用 | `boolean` | `false` | 否 |
| plus | true 时父级可选；false 时仅叶子可选，初始化时读取 | `boolean` | `false` | 否 |
| maxLevel | 仅 options 模式生效：超过该层级的节点禁用，范围 1～5 | `number` | `5` | 否 |

## Events

| 事件 | 参数 | 说明 |
| --- | --- | --- |
| update:modelValue | value: string \| undefined | 选择/清空时连接编码；远程非空回显 nextTick 也触发 |
| change | value: string \| undefined | 级联 change 或远程非空回显时；options 模式 change 会截取 maxLevel，但更新事件未同步截取；回显顺序为 update 后 change |

## v-model

`v-model` 绑定逗号分隔的区域编码字符串，空值使用 `''`；清空时也可能输出 `undefined`。

## 注意事项

- 传入 options 使用静态数据，包括空数组；不传 options 时，通过注入的 request 请求 GET /admin/sysArea/tree，参数为 { type }，返回 { data: 节点数组 }。缺少两种数据来源时显示空列表。
- 请求在挂载时执行，后续修改 type 不会重新查询；plus 也只在初始化时读取。需要切换时重新挂载组件。
- 远程数据加载或非空绑定值回显时，会依次触发 update:modelValue、change。避免在 change 中无条件写回另一个非空值。
- 静态模式的 maxLevel 不会将非叶子节点转换成叶子；自动请求的层级由 type 决定。placeholder、clearable 等属性透传给 Cascader。
- 清空可能输出 undefined；自动请求数据中 hot 为字符串 "1" 时显示热区图标。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';
import type { CascaderOption, ElCascader } from 'element-plus';

declare const AuraChinaArea: DefineComponent<Omit<InstanceType<typeof ElCascader>['$props'], 'modelValue' | 'options' | 'props' | 'onChange' | 'onUpdate:modelValue'> & {
  modelValue?: string;
  options?: CascaderOption[];
  type?: number;
  disabled?: boolean;
  plus?: boolean;
  maxLevel?: number;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: string | undefined) => void;
  change: (value: string | undefined) => void;
}>;

export default AuraChinaArea;
```

API 资料来自 `docs/component/china-area.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
