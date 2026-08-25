# CSS 与 Tailwind 强制规范

## 总原则

业务样式必须遵循以下顺序：

1. **能用 Tailwind 工具类表达的样式，必须使用 Tailwind。**
2. **Tailwind 无法清晰表达、需要复杂选择器、状态联动、组件穿透或页面模块私有样式时，才写 SCSS。**
3. **Tailwind 和 SCSS 中涉及颜色、背景、边框、阴影、文本颜色时，必须使用 Element Plus 主题变量。**
4. **不得写死十六进制颜色、rgb/rgba 固定色、固定主题色常量。**

## Tailwind 使用范围

以下场景必须使用 Tailwind：

- flex / grid 布局
- gap / padding / margin 等常规间距
- width / height / min/max 尺寸
- border radius
- 文本大小、字重、对齐
- overflow、定位、z-index 等通用布局
- hover / focus 等简单状态
- 响应式布局

示例：

```vue
<div class="flex items-center justify-between gap-3 rounded-lg p-4">
  <div class="min-w-0 flex-1">
    <h3 class="truncate text-base font-semibold">标题</h3>
    <p class="mt-1 text-sm">说明文字</p>
  </div>
</div>
```

## 什么时候允许写 SCSS

以下场景允许写 SCSS：

- Tailwind 难以表达的复杂嵌套选择器。
- Element Plus 组件局部穿透，例如 `:deep(.aura-table__cell)`。
- 页面模块私有样式很多，需要拆到 `src/views/<module>/<page>/styles/`。
- 多页面复用的页面级样式，需要沉淀到 `src/styles/page.scss`。
- 动画关键帧、复杂渐变、复杂状态联动。

## Tailwind 颜色强制规则

Tailwind 颜色类必须映射 Element Plus 主题变量。允许两类写法：

### 方式一：使用已配置的主题语义类

如果项目 Tailwind 主题中已经配置对应语义类，必须使用语义类：

```vue
<div class="bg-primary text-primary border-br-light">
  内容
</div>
```

语义类必须最终映射到 Element Plus CSS 变量，例如：

```css
--color-primary: var(--el-color-primary);
--color-br-light: var(--el-border-color-light);
```

### 方式二：使用 Tailwind 任意值绑定 CSS 变量

如果当前项目未配置语义色，必须使用 Tailwind 任意值写法绑定 Element Plus 变量：

```vue
<div class="border border-[var(--el-border-color-light)] bg-[var(--el-color-white)] text-[var(--el-text-color-primary)] shadow-[var(--el-box-shadow-light)]">
  内容
</div>
```

## 禁止写法

```vue
<!-- 禁止：写死颜色 -->
<div class="bg-[#fff] text-[#333] border-[#ebeef5]">内容</div>

<!-- 禁止：固定 rgba 主题色 -->
<div class="shadow-[0_12px_32px_rgba(15,23,42,0.12)]">内容</div>

<!-- 禁止：能用 Tailwind 却写 SCSS -->
<style scoped>
.card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px;
}
</style>
```

## SCSS 颜色强制规则

写 SCSS 时，颜色仍然必须使用 Element Plus CSS 变量：

```scss
.page-card {
  background: var(--el-color-white);
  color: var(--el-text-color-primary);
  border: 1px solid var(--el-border-color-light);
  box-shadow: var(--el-box-shadow-light);
}
```

禁止：

```scss
.page-card {
  background: #fff;
  color: #333;
  border: 1px solid #ebeef5;
}
```

## 与公共样式的关系

- 多页面复用的样式写入 `src/styles/page.scss`。
- 页面模块私有样式较多时，写入 `src/views/<module>/<page>/styles/`。
- 单组件少量私有样式写在组件 `<style scoped lang="scss">`。
- 无论写在哪里，颜色都必须使用 Element Plus CSS 变量。

## 交付要求

每次涉及样式变更，交付说明必须包含：

- 哪些样式使用了 Tailwind。
- 哪些样式因 Tailwind 不适合而写了 SCSS。
- 使用了哪些 Element Plus 主题变量。
- 是否新增/修改了 `src/styles/page.scss` 或页面模块 `styles/`。
