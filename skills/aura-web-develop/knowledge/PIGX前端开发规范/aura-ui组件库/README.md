# aura-ui 组件库说明

仅覆盖 `@fxft/aura-ui` 的 `AuraDictTag`、`AuraDictText`、`AuraDictSelect`，供开发与审查按需取证。基线为实际安装包 **1.1.2** 的声明和运行实现；上游说明是补充依据，不能用源码仓库当前 **1.1.5** 覆盖目标项目版本。本目录目前只介绍三个字典组件，不构建整个 SDK 文档库；只说明 Select 已有公开加载能力，不另建字典加载器，也不审计 SDK 底层。目标项目版本不同须重新核对公开契约。

## 组件索引与按需读取

命中组件接入时先读本入口和项目实际依赖；使用/审查哪个组件，再仅加载对应页面。使用多个组件时才读取对应多页。

| 公开组件 | 组件说明 |
| --- | --- |
| `AuraDictTag` | [DictTag](DictTag.md)：标签、多值、图标插槽及空值行为 |
| `AuraDictText` | [DictText](DictText.md)：单值文本、fallback 与文字样式 |
| `AuraDictSelect` | [DictSelect](DictSelect.md)：单选/多选、v-model、项目选项或公开远程加载 |

## 公开入口与接入

| 入口 | 1.1.2 已核实的契约 |
| --- | --- |
| `@fxft/aura-ui` | 根声明与 ESM 产物均命名导出 `AuraDictTag`、`AuraDictText`、`AuraDictSelect`；根声明另导出类型 `AuraDictOption`、`AuraDictValue`、`AuraDictRequest` |
| `@fxft/aura-ui/dict-tag` / `@fxft/aura-ui/dict-text` / `@fxft/aura-ui/dict-select` | package exports 分别提供 types/import/require 路径；组件子入口为 default 导出 |
| `@fxft/aura-ui/resolver` | `AuraUIResolver` 命名及 default 导出；解析三组件为 `@fxft/aura-ui/dist/es/components/dict-{tag,text,select}/index.js` 的 default 导入 |
| Resolver 样式 | 默认注入 `dist/theme-chalk/var.css`、`base.css` 及 `dict-tag.css` / `dict-text.css` / `dict-select.css`；`importStyle=false` 关闭组件 CSS，`injectGlobal=false` 关闭全局 CSS |

不得把源码仓库名 `aura-web-sdk` 写为虚构的 `@fxft/aura-web-sdk` 包，或把文档标题 `DictTag` / `DictText` 当作公开组件名。显式导入与 Resolver 自动导入均需核对项目实际配置和依赖文件，不能仅凭标签存在判定已接入；显式导入时同时遵循项目样式接入约定。

```vue
<script setup lang="ts">
import AuraDictTag from '@fxft/aura-ui/dict-tag';
import AuraDictText from '@fxft/aura-ui/dict-text';
import type { AuraDictOption } from '@fxft/aura-ui';

// statusOptions 来自调用方已加载的项目字典；本例不构造业务固定选项。
defineProps<{
  status: string | number;
  statusOptions: AuraDictOption[];
}>();
</script>

<template>
  <AuraDictTag :value="status" :options="statusOptions" />
  <AuraDictText :value="status" :options="statusOptions" />
</template>
```

Tag/Text 只消费 `options`，不会自动请求字典。Mock 可为项目字典入口提供演示选项，不得将演示固定选项硬编码进业务页面。筛选和表单使用 `AuraDictSelect` 或项目字典选项，Select 的类型、事件与远程加载见对应页。

## 组件 Props 能力差异

| 组件 | 模型 / 多值 | 字段键 | 远程加载与空值展示 |
| --- | --- | --- | --- |
| Tag | value，单值/数组，String 匹配 | labelKey/valueKey/tagTypeKey/tagClassKey | 不请求，emptyText 只用于有选择但完全不匹配 |
| Text | value，仅单值，首个 String 匹配 | 固定 label/value | 不请求，fallback 为空时回退原始编码 |
| Select | modelValue，单选/多选数组，值类型保留 | labelKey/valueKey | options 或 dictType/request；无 emptyText/fallback，清空遵循 ElSelect 配置 |

## 共用字典选项字段

`AuraDictOption` 声明允许 `[key: string]: unknown`，以下字段全部可选。扩展字段不代表三个组件都会消费；Select 仅取 label/value（支持自定义键），不消费 elTagType/elTagClass/icon/color。

| 字段 | 声明类型 | Tag 消费 | Text 消费 |
| --- | --- | --- | --- |
| `label` | `string` | 显示文本；可由 labelKey 指定字段优先覆盖 | 显示文本；回退规则见对应组件页 |
| `value` | `string \| number` | 匹配编码；可由 valueKey 指定字段优先覆盖 | 匹配编码，不支持自定义键 |
| `elTagType` | `string` | 语义类型；可由 tagTypeKey 指定字段优先覆盖 | 语义类型，限定五种有效值 |
| `elTagClass` | `string` | CSS 类；可由 tagClassKey 指定字段优先覆盖 | CSS 类 |
| `icon` | `string` | showIcon 及渲染条件满足时消费 | 不消费 |
| `color` | `string` | 文字、边框及背景颜色 | 文字颜色 |

`AuraDictRequest` 是字典请求函数类型，返回选项数组或 `{ data: 选项数组 }` 及它们的 Promise；是 Select 的 request prop 类型；不是 Tag/Text 的 prop、方法或自动请求承诺。

## 审查使用边界

沿接口枚举/dictKey → 消费字段 → 页面及嵌套/历史组件 → 实际展示取证，再核对安装版本、公开入口、真实 Props 和 Resolver/import；筛选/表单的 Select 同样核对真实 options 来源、模型类型、multiple 和事件消费。业务枚举展示不能以 map/find/switch/三元/getLabel、手工 el-tag 或对应 *Name 快照替代组件。状态机、权限等非展示判断、数字单位及无字典真实名称不按此误报。组件缺失如实记录偏差或缺证，不自动升级或改为手写映射。

## 证据与维护来源

核对日期：2026-10-23。上游仓库 `other/aura-web-sdk.git`，提交 `3e9d3701bc14d500b5ebcd0df002546dd3b1ee78`，`packages/ui/package.json` 当前为 1.1.5；本次所读 docs 与 packages/ui 无 tracked 差异，仓库存在未跟踪的构建/打包资料。只读核对，未改上游。安装包证据取自目标项目的 `node_modules/@fxft/aura-ui`，版本 1.1.2；以下路径均相对表内证据根，SHA-256 按原始文件字节计算，不依赖读者本机路径。

| 证据根 | 相对路径 | SHA-256 |
| --- | --- | --- |
| `@fxft/aura-ui@1.1.2` | `package.json` | `665c43b1b251231ebf993e8add7a38e58ebcee62497ee0d0b40d2a3823892ef5` |
| `@fxft/aura-ui@1.1.2` | `index.d.ts` | `b91186894b01498295edddc22febffcf0a9392b1b0a881669fc365d54ac75d27` |
| `@fxft/aura-ui@1.1.2` | `dist/es/index.js` | `e7fd756851fda2b5d5194382d207340b8810d2e0e14309423bac998d3880aaa5` |
| `@fxft/aura-ui@1.1.2` | `components/dict-tag/index.d.ts` | `67f284d79385f5b7506843ee299f7e893e8659a794fbfb10b989d7afa4656e26` |
| `@fxft/aura-ui@1.1.2` | `components/dict-text/index.d.ts` | `49af0715358c81e618d291dbd68ef1880ba26f17a2dc6ea11674b2260a8bb8cd` |
| `@fxft/aura-ui@1.1.2` | `dist/es/components/dict-tag/index.d.ts` | `67f284d79385f5b7506843ee299f7e893e8659a794fbfb10b989d7afa4656e26` |
| `@fxft/aura-ui@1.1.2` | `dist/es/components/dict-text/index.d.ts` | `49af0715358c81e618d291dbd68ef1880ba26f17a2dc6ea11674b2260a8bb8cd` |
| `@fxft/aura-ui@1.1.2` | `dist/es/components/dict-tag/index.js` | `68e9480f035eba214c037a4e5ea9d3146c3aa29c92ef71e544463986d4f24b09` |
| `@fxft/aura-ui@1.1.2` | `dist/es/components/dict-text/index.js` | `c3806c06181af82e5a5bbe288d981401dc22a37a3d2ff58828843ac9d3d2f127` |
| `@fxft/aura-ui@1.1.2` | `dist/es/components/dict-tag/dict-tag.vue.js` | `a0e5257117aa9bc4d3901f2c7f571f5e683cf34afd88b5b3de552e6d66b48676` |
| `@fxft/aura-ui@1.1.2` | `dist/es/components/dict-text/dict-text.vue.js` | `8552a846ab1a867ec9e9295ddd4dbd3e95193d004803c89c69231130e0574b2a` |
| `@fxft/aura-ui@1.1.2` | `types/dict.d.ts` | `988cedb0ffd7def8231448ecc9b05fac0cfdbc0e9c49fa36674d42e20ea9701c` |
| `@fxft/aura-ui@1.1.2` | `dist/es/types/dict.d.ts` | `988cedb0ffd7def8231448ecc9b05fac0cfdbc0e9c49fa36674d42e20ea9701c` |
| `@fxft/aura-ui@1.1.2` | `resolver.mjs` | `673f38b3298d0101373b3ae48a9378d359e4e1585b5d996f70ef3d07c1ff5751` |
| `aura-web-sdk@3e9d3701bc14d500b5ebcd0df002546dd3b1ee78` | `docs/component/dict-tag.md` | `5d36e17a56866b80429943a0e7f0d3e1c4bb90448a8d48425608adc192d9af64` |
| `aura-web-sdk@3e9d3701bc14d500b5ebcd0df002546dd3b1ee78` | `docs/component/dict-text.md` | `1e8061cef298c97b1fbac053534fd697e6590c9df5a5b4449a014a535855d4cf` |
| `aura-web-sdk@3e9d3701bc14d500b5ebcd0df002546dd3b1ee78` | `packages/ui/package.json` | `c4925ab16a33dac0cb07c49989f794f964712bc6e6fe52f56c84d815149bc988` |
| `@fxft/aura-ui@1.1.2` | `components/dict-select/index.d.ts` | `80e305a28d0390d66c7d8a0d7f3ff3cdba5d89ebf3ce7d10143a3d42ddafd372` |
| `@fxft/aura-ui@1.1.2` | `dist/es/components/dict-select/index.d.ts` | `80e305a28d0390d66c7d8a0d7f3ff3cdba5d89ebf3ce7d10143a3d42ddafd372` |
| `@fxft/aura-ui@1.1.2` | `dist/es/components/dict-select/index.js` | `82fc3d30e5164ec66c9319c99b6060e130554a5d278e25b678d68b1ba8b92378` |
| `@fxft/aura-ui@1.1.2` | `dist/es/components/dict-select/dict-select.vue.js` | `0c3a682c3794a1a110b326b9d236ea023c6e1671d9b6504ab16020a3d69afbc4` |
| `aura-web-sdk@3e9d3701bc14d500b5ebcd0df002546dd3b1ee78` | `docs/component/dict-select.md` | `2eaca6316f7ca114c8604d1f6026f2fe57f9823b87c7f87cd657003ec1e99a1c` |

本目录由 aura-web-develop 维护；aura-web-review 随包保存字节相同的只读副本，运行不要求跨技能读取。来源与本地工作树状态另见 [本地变更记录](../../../references/readability-source.json)。本文为用户授权的本地规则/契约资料补充，不表示规范源已经同步或技能已经安装发布。
