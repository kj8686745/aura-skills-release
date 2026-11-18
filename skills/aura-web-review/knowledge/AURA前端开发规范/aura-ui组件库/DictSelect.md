# AuraDictSelect

字典单选/多选组件。包版本、公开导入、共用字段及证据见 [组件库入口](README.md)，本页以 `@fxft/aura-ui@1.1.2` 的声明与运行产物为准；仅加载/审查本组件时无需读取 Tag/Text 页面。

## Props

以下均可选；`AuraDictValue = string | number`。

| Prop | 声明类型 | 默认值 / 作用 |
| --- | --- | --- |
| `modelValue` | `AuraDictValue \| AuraDictValue[] \| null` | `undefined`；通过 v-model 绑定，单选为 string/number，可为 null/undefined；多选为数组，空选通常用 `[]` |
| `options` | `Array<AuraDictOption \| AuraDictValue>` | `[]`；dictType 为空时使用的项目字典选项 |
| `placeholder` | `string` | `'请选择'`；业务必须显式传入真实 i18n placeholder，不能依赖该中文默认值 |
| `multiple` | `boolean` | `false`；启用多选，不在包装组件内强制转换模型类型 |
| `disabled` | `boolean` | `false` |
| `clearable` | `boolean` | `true`；清除后的值由 ElSelect / ElConfigProvider 的实际配置决定，不承诺固定返回空字符串或 null |
| `dictType` | `string` | `''`；非空则选用内部远程选项，不再显示静态 options |
| `request` | `AuraDictRequest` | 运行默认 `null`；prop 为函数且非空时优先。声明未将 null 纳入该可选 prop，不能照最新文档强写 null 的类型承诺 |
| `labelKey` | `string` | `'label'`；对象选项展示字段，回退 `option.label ?? ''` |
| `valueKey` | `string` | `'value'`；对象取值字段，回退 `option.value ?? ''`，保留 number/string 原始类型 |
| `autoLoad` | `boolean` | `true`；初始化及 dictType/加载函数/autoLoad 变化时检查加载条件；false 停止自动加载，无公开手动加载方法 |

`filterable` **不是组件自身声明的 Prop**。组件为单个 ElSelect 根节点，未关闭 attrs 继承；该属性可作为 ElSelect 透传属性使用，需核对实际 Element Plus 版本及配置。不把 `filterable`、`emptyValues`、`valueOnClear` 等下层透传能力记为组件自身 API 或虚构它们的默认值。本组件没有 `value` Prop、`emptyText` 或 `fallback`。

## 选项归一化、模型与空值

- 过滤 options 中的 null/undefined；字符串或数字选项变为 `{ label: String(item), value: item }`，`0` 有效。
- 对象显示取 `option[labelKey] ?? option.label ?? ''`，取值取 `option[valueKey] ?? option.value ?? ''`。空字符串字段保留，不像 Text 那样用逻辑或回退；不会以 label 代替缺失 value。
- 值类型保留：数字 `0` 与字符串 `'0'` 不在此组件内互转，也不执行 Tag/Text 的 String 匹配归一化；选择匹配和清空行为交给实际 ElSelect。业务绑定的值与字典 value 类型应一致，多选绑定数组。
- 未指定 dictType 时直接归一化项目 options；指定 dictType 后，即使远程结果为空、缺少加载方法或关闭自动加载，也不会回退静态 options。空列表由 ElSelect 呈现，本组件没有自定义空态插槽。

## 远程请求与异步行为

加载方法优先顺序为组件 `request(dictType)` → 注入的公共 request 适配。后者通过 `@fxft/aura-web-kit/api/common` 的 `createCommonApi(注入request).getDicts(dictType)` 调用字典接口；只核公开调用，不把项目 HTTP request 实例直接冒充只接收 dictType 的组件 request 回调。

回调应按 `AuraDictRequest` 返回选项数组或 `{ data: 选项数组 }`，可返回 Promise。dictType 非空、autoLoad=true 且方法可用时自动加载；缺少方法只警告一次。加载失败时实现弹出“字典数据加载失败”并清空远程选项；这是 SDK 1.1.2 的现有行为，不宣称项目业务层可据此对所有只读请求增加全局提示。

监听清理及当前 dictType/方法/autoLoad 比对阻止旧请求写回；切换 dictType 先清空原远程选项，再按条件加载。组件没有公开 refresh/load/取消请求函数。仅供弹窗的字典仍遵守项目按打开时加载的业务要求，不能因组件 autoLoad 默认开启就绕过；可由项目字典选项来源按需加载后传 options，具体采用已验证公开能力。

## Events、Slots 与 Methods

| 公开项 | 契约 |
| --- | --- |
| `update:modelValue` | ElSelect 触发模型更新时，先发送该事件；payload 原样为 string/number/数组/null/undefined |
| `change` | 在同一次模型更新处理函数中紧随 update:modelValue 发送相同 payload；不是等待远程字典加载成功的事件 |
| 自定义 Slots | 未提供；默认子内容由组件生成 ElOption，没有自定义插槽转发契约 |
| 暴露函数 / 实例方法 | 未提供；没有 refresh/load/getLabel 或暴露的 ElSelect 实例方法 |

## 最小用法

```vue
<script setup lang="ts">
import { ref } from 'vue';
import AuraDictSelect from '@fxft/aura-ui/dict-select';
import type { AuraDictOption } from '@fxft/aura-ui';

// 由调用方按真实项目字典入口提供选项，不在业务页面硬编码伪字典。
defineProps<{ statusOptions: AuraDictOption[] }>();
/** 当前筛选的状态编码；清空值由项目 ElSelect 配置决定 */
const status = ref<string | number | null | undefined>();
</script>

<template>
  <!-- 状态筛选：按项目字典状态编码缩小业务列表范围 -->
  <AuraDictSelect v-model="status" :options="statusOptions" :placeholder="$t('common.selectPlaceholder')" />
</template>
```

示例语言 key 必须替换为项目真实已存在的 key；多选时以数组模型配合 multiple。Mock 字典选项只能用于演示或项目字典入口测试，不得作为业务页固定映射。
