# AuraMdRenderer Markdown 渲染器

公共子入口 `@fxft/aura-ui/md-renderer`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

渲染 Markdown，支持代码高亮和明暗主题。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraMdRenderer from '@fxft/aura-ui/md-renderer';
</script>

<template>
  <AuraMdRenderer source="# 示例标题" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| source | Markdown 文本内容 | `string` | `''` | 否 |
| isDark | 显式指定深色主题；未传时读取应用配置 | `boolean` | `undefined` | 否 |
| inner_suffix | 当前不生效 | `boolean` | `false` | 否 |
| lineNumber | 代码块是否显示行号 | `boolean` | `true` | 否 |
| copyCode | 代码块是否显示复制按钮 | `boolean` | `true` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| rendered | Cherry 实例构造成功；source setValue 不额外触发，远程资源可能尚未加载 | 无 |
| error | Cherry 动态加载或实例初始化失败；不承诺覆盖所有 setValue/资源错误 | error: unknown |

## 注意事项

- isDark 属性优先于公共 mdRenderer.isDark 回调，默认浅色。source 改变会更新内容，主题改变会销毁并重建渲染器。
- lineNumber 和 copyCode 在初始化或主题重建时读取，单独修改不会立即生效；inner_suffix 当前未使用。
- rendered 仅表示渲染器创建完成，图片等远程资源可能仍在加载。
- HTML 按 Cherry 的解析规则处理，不包含额外的通用 HTML 过滤。
- 依赖浏览器 DOM；Cherry 0.9.3 的实例销毁仍存在计时器残留问题，频繁重建场景需关注。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraMdRenderer: DefineComponent<{
  source?: string;
  isDark?: boolean;
  inner_suffix?: boolean;
  lineNumber?: boolean;
  copyCode?: boolean;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  rendered: () => void;
  error: (error: unknown) => void;
}>;

export default AuraMdRenderer;
```

API 资料来自 `docs/component/md-renderer.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
