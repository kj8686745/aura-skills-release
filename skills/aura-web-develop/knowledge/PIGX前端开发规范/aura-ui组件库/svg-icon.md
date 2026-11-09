# AuraSvgIcon 图标

公共子入口 `@fxft/aura-ui/svg-icon`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

统一显示 Element Plus 图标、本地 SVG symbol、图片和字体图标。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraSvgIcon from '@fxft/aura-ui/svg-icon';
</script>

<template>
  <AuraSvgIcon name="ele-Edit" :size="20" />
</template>
```

## 图标类型

### 1. Element Plus 内置图标

使用 `ele-` 前缀，后跟 Element Plus 图标名称：

```vue
<script setup lang="ts">
import AuraSvgIcon from '@fxft/aura-ui/svg-icon';
</script>

<template>
<AuraSvgIcon name="ele-Edit" :size="24" color="#409EFF" />
</template>
```

### 2. 本地 SVG 图标

使用 `local-` 前缀，默认保留完整名称作为页面中 symbol 的 ID：

```vue
<script setup lang="ts">
import AuraSvgIcon from '@fxft/aura-ui/svg-icon';
</script>

<template>
<svg style="display: none"><symbol id="local-home" viewBox="0 0 24 24"><path d="M2 12 12 2 22 12v10H2z" /></symbol></svg>
<AuraSvgIcon name="local-home" :size="24" color="#409EFF" />
</template>
```

### 3. 图片图标

直接使用图片 URL：

```vue
<script setup lang="ts">
import AuraSvgIcon from '@fxft/aura-ui/svg-icon';
</script>

<template>
<AuraSvgIcon name="/assets/logo.svg" :size="24" />
</template>
```

### 4. 自定义样式

通过 `size`、`color` 和 `className` 属性自定义图标样式：

```vue
<script setup lang="ts">
import AuraSvgIcon from '@fxft/aura-ui/svg-icon';
</script>

<template>
<AuraSvgIcon
  name="ele-Edit"
  :size="32"
  color="#67C23A"
  className="custom-icon"
/>
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| name | 图标名称，支持以下格式：<br>- `ele-` 前缀：Element Plus 内置图标<br>- `local-` 前缀：本地 SVG 图标<br>- 图片链接：在线或本地图片 | `string` | `undefined` | 否 |
| src | 图片地址，优先于 name；支持业务通过 import 得到的资源 URL | `string` | `undefined` | 否 |
| size | 图标大小 | `number` | `14` | 否 |
| color | 图标颜色 | `string` | `undefined` | 否 |
| className | 自定义类名 | `string` | `''` | 否 |
| pathPrefix | 为未匹配已知前缀的普通名称拼接图片地址前缀；不改变 ele-/local- | `string` | `''` | 否 |
| pathPrefixes | 额外识别为图片地址的前缀 | `string[]` | `[]` | 否 |

## 注意事项

- ele-* 对应 Element Plus 图标名；local-home 默认引用页面中的 #local-home symbol。字体名称作为 class 输出，需要应用加载字体 CSS。
- src 优先于 name。图片前缀默认识别 /、http、https、data:image 等，可通过 pathPrefix、pathPrefixes 扩展。
- className 属性只作用于本地 SVG 分支；公共 svgIcon.className 可为各分支补充类名。
- 公共 svgIcon.localSvgPrefix 默认 local-，只在 symbol ID 规则不同时覆盖。imageStyle(size, color) 可自定义图片内部样式。
- 图片着色使用滤镜。组件不负责下载 SVG 文件、加载字体或处理图片鉴权和代理。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { DefineComponent } from 'vue';

declare const AuraSvgIcon: DefineComponent<{
  name?: string;
  src?: string;
  size?: number;
  color?: string;
  className?: string;
  pathPrefix?: string;
  pathPrefixes?: string[];
}>;

export default AuraSvgIcon;
```

API 资料来自 `docs/component/svg-icon.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
