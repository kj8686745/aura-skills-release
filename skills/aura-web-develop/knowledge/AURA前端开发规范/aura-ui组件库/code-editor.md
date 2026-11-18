# AuraCodeEditor 代码编辑器

公共子入口 `@fxft/aura-ui/code-editor`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

基于 CodeMirror 5 的代码编辑器，支持代码高亮、只读模式和 JSON 格式化。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraCodeEditor from '@fxft/aura-ui/code-editor';
import { ref } from 'vue';

const value = ref('{"name": "示例"}');
</script>

<template>
  <AuraCodeEditor v-model="value" mode="javascript" :height="240" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 绑定值 | `string` | `''` | 否 |
| mode | 语言模式 | `string` | `'go'` | 否 |
| height | 编辑器高度 | `string \| number` | `300` | 否 |
| theme | 主题 | `string` | `'idea'` | 否 |
| readOnly | 是否只读 | `boolean` | `false` | 否 |
| options | 自定义配置，覆盖默认编辑器配置 | `Record<string, any>` | `undefined` | 否 |

## mode 可选值

| 值 | 说明 |
| --- | --- |
| go | Go 语言 |
| velocity | Velocity 模板 |
| javascript | JavaScript |
| xml | XML |
| css | CSS |
| htmlmixed | HTML 混合 |

## theme 可选值

| 值 | 说明 |
| --- | --- |
| idea | IntelliJ IDEA 主题 |
| darcula | Darcula 深色主题 |

## options 配置项

| 属性 | 说明 | 类型 | 默认值 |
| --- | --- | --- | --- |
| lineNumbers | 是否显示行号 | Boolean | true |
| lineWrapping | 是否自动换行 | Boolean | false |
| tabSize | Tab 缩进大小 | Number | 4 |
| indentUnit | 缩进单位 | Number | 4 |
| indentWithTabs | 是否使用 Tab 缩进 | Boolean | true |
| styleActiveLine | 是否高亮当前行 | Boolean | true |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:modelValue | CodeMirror change 回调先发送，包含外部 setValue 触发的 change | value: string |
| change | 紧随 update:modelValue | value: string |

## Methods

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| init | 初始化编辑器；组件挂载时自动调用，勿对同一实例重复初始化 | 无 | void |
| formatStrInJson | JSON.parse 后按 4 空格 JSON.stringify；无效 JSON 同步抛错；不写回编辑器 | value: string | string |

## v-model

`v-model` 绑定代码字符串，空值使用 `''`。

## 注意事项

- mode、theme、readOnly、options 只在初始化时读取；需要切换时通过 key 重建。height 和 modelValue 可动态更新。
- 外部内容变化会调用 setValue，并触发 update:modelValue 和 change；业务监听时应避免重复保存。
- formatStrInJson 返回格式化字符串，不写回编辑器；无效 JSON 会抛出异常。
- 组件 ref 还可访问 coder、contentValue、opt 和 _height。init 在挂载时自动调用，不要对同一实例重复初始化。
- 依赖浏览器 DOM，SSR 应用需在客户端加载。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraCodeEditor: DefineComponent<{
  modelValue?: string;
  mode?: string;
  height?: string | number;
  options?: Record<string, any>;
  theme?: string;
  readOnly?: boolean;
}, {
  coder: any;
  contentValue: string;
  opt: Record<string, any>;
  _height: string | number;
  init: () => void;
  formatStrInJson: (value: string) => string;
}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: string) => void;
  change: (value: string) => void;
}>;

export default AuraCodeEditor;
```

API 资料来自 `docs/component/code-editor.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
