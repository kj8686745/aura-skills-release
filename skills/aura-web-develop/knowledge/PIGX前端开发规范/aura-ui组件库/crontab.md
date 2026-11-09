# AuraCrontab Cron 表达式生成器

公共子入口 `@fxft/aura-ui/crontab`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

通过快捷选项或可视化面板生成 Cron 表达式。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraCrontab from '@fxft/aura-ui/crontab';
import { ref } from 'vue';

const value = ref('0 * * * * ?');
</script>

<template>
  <AuraCrontab v-model="value" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 当前 CronTab 表达式值，支持 v-model 双向绑定 | `string` | `'* * * * * ?'` | 否 |
| shortcuts | 自定义快捷选项数组，每个选项包含 `value` 和 `text` 属性 | `{ text: string; value: string }[]` | `[]` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:modelValue | 快捷项选择或生成器 submit；手工输入不触发 | value: string |

## Methods

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| open | 解析当前 modelValue 后打开生成器 | 无 | void |
| set | 按当前 modelValue 重新解析生成器选项 | 无 | void |
| submit | 拼接表达式、emit 更新并关闭 | 无 | void |
| handleShortcuts | custom 打开，其余命令作为表达式直接输出 | command: string | void |
| getYear | 返回从当前年开始的连续 11 年 | 无 | number[] |

## v-model

`v-model` 绑定表达式字符串，默认 `* * * * * ?`。

## 注意事项

- 手动输入只修改输入框显示；选择快捷项或确认生成器后才更新绑定值。需要直接编辑并保存表达式时，应自行处理输入。
- 解析器未完整校验数值范围或覆盖全部 Quartz 语法；表达式应由实际调度器校验。
- 传空字符串时输入框为空，打开生成器后按默认表达式解析。复杂表达式和年份间隔的回填结果需核对。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';
import type { InputProps } from 'element-plus';

declare const AuraCrontab: DefineComponent<Partial<Omit<InputProps, 'modelValue'>> & {
  modelValue?: string;
  shortcuts?: { text: string; value: string }[];
}, {
  open: () => void;
  set: () => void;
  submit: () => void;
  handleShortcuts: (command: string) => void;
  getYear: () => number[];
}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: string) => void;
}>;

export default AuraCrontab;
```

API 资料来自 `docs/component/crontab.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
