# public 静态资源模板

本示例使用 `public/images/empty-state.png`。消费项目使用 `@fxft/aura-web-kit` 1.13.1 或兼容后续版本。单 MF 在 Vite 设置 `experimental.renderBuiltUrl: renderFederationAssetUrl`。双架构使用 `createFederationAssetUrlRenderer({ cssUrlMode: isQiankun ? 'base' : 'relative' })`。Vite 识别的 public 引用默认随 JS 模块或外链样式表定位。具体配置和校验见[静态资源规范](../knowledge/AURA前端开发规范/样式布局与静态资源规范.md#七public-资源)和[联邦构建配置](../knowledge/AURA前端开发规范/模块联邦开发技术规范.md#6-构建静态资源地址)。

升级时从已有配置移除 `publicUrlMode`。HTML 和 SSR 资源按项目的 Vite 配置处理。

以下 SFC 分别使用 `?url` 导入绑定图片、编译 CSS 的 `url()` 和 Vue 的 `:style` 绑定导入值。

```vue
<script setup lang="ts">
import publicEmptyImage from '/images/empty-state.png?url';
</script>

<template>
  <img :src="publicEmptyImage" alt="" />
  <div class="public-css-example" aria-hidden="true"></div>
  <div
    class="public-style-example"
    :style="{ backgroundImage: `url(${publicEmptyImage})` }"
    aria-hidden="true"></div>
</template>

<style scoped>
.public-css-example,
.public-style-example {
  width: 120px;
  height: 120px;
  background: center / contain no-repeat;
}

.public-css-example {
  background-image: url('/images/empty-state.png');
}
</style>
```

普通行内样式、SDK 参数和运行时拼接中需要解析 public 路径时，使用项目的 `getPublicResourceUrl`，再绑定得到的 URL。qiankun 内联 CSS 使用 `cssUrlMode: 'base'`，由宿主提供对应部署前缀。
