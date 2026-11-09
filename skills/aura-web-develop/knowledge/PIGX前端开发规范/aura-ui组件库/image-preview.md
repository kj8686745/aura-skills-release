# AuraImagePreview 图片预览

公共子入口 `@fxft/aura-ui/image-preview`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

显示图片并提供单图预览，支持应用统一解析文件地址。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraImagePreview from '@fxft/aura-ui/image-preview';
</script>

<template>
  <AuraImagePreview src="/REPLACE_WITH_PUBLIC_IMAGE_URL.png" preview style="width: 80px; height: 80px" />
</template>
```

## Attributes

| 属性 | 说明 | 默认值 | 类型 | 必填 |
| --- | --- | --- | --- | --- |
| src | 图片地址，经可选 getFileUrl 转换 | `''` | `string` | 否 |
| fit | 图片填充模式 | `'contain'` | `'fill' \| 'contain' \| 'cover' \| 'none' \| 'scale-down'` | 否 |
| preview | 使用转换后的 src 开启单图预览 | `false` | `boolean` | 否 |
| previewTeleported | 预览层挂到 body | `false` | `boolean` | 否 |

## Slots

| 插槽名 | 说明 | 参数 |
| --- | --- | --- |
| error | 图片错误占位；其他 ElImage 插槽不转发 | 无 |

## 注意事项

- 公共 getFileUrl 用于转换 src；未配置时直接使用传入地址。
- preview=false 时不生成预览列表；显式 preview-src-list 可覆盖单图列表，列表中的地址不会再次转换。
- 其他属性和 `load`、`error`、`show`、`close`、`switch` 监听器透传给 ElImage。只转发 `error` 插槽，不提供 `showPreview` 实例方法。
- 图片地址、鉴权和资源代理由应用处理。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { DefineComponent } from 'vue';
import type { ElImage } from 'element-plus';

declare const AuraImagePreview: DefineComponent<Omit<InstanceType<typeof ElImage>['$props'], 'fit'> & {
  fit?: 'fill' | 'contain' | 'cover' | 'none' | 'scale-down';
  preview?: boolean;
}>;

export default AuraImagePreview;
```

API 资料来自 `docs/component/image-preview.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
