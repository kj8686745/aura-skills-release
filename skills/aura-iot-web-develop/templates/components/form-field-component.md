# 模板：表单项组件

## 适用场景

- 复合输入项。
- 带业务说明的表单项。
- 需要在多个表单中复用同一输入结构。
- 与 Element Plus `el-form-item` 配合使用。

## 模板

```vue
<script setup lang="ts">
const modelValue = defineModel<string>({ default: '' })

withDefaults(
  defineProps<{
    label: string
    prop?: string
    placeholder?: string
    required?: boolean
    disabled?: boolean
    tip?: string
  }>(),
  {
    prop: '',
    placeholder: '请输入',
    required: false,
    disabled: false,
    tip: '',
  },
)
</script>

<template>
  <el-form-item :label="label" :prop="prop" :required="required">
    <div class="w-full">
      <el-input
        v-model="modelValue"
        :placeholder="placeholder"
        :disabled="disabled"
        clearable
      />
      <p v-if="tip" class="mt-1 text-xs text-[var(--el-text-color-secondary)]">
        {{ tip }}
      </p>
    </div>
  </el-form-item>
</template>
```

## 选项型表单项

```vue
<script setup lang="ts">
export interface SelectOption {
  label: string
  value: string
  disabled?: boolean
}

const modelValue = defineModel<string>({ default: '' })

withDefaults(
  defineProps<{
    label: string
    prop?: string
    options: SelectOption[]
    placeholder?: string
    disabled?: boolean
  }>(),
  {
    prop: '',
    placeholder: '请选择',
    disabled: false,
  },
)
</script>

<template>
  <el-form-item :label="label" :prop="prop">
    <el-select v-model="modelValue" class="w-full" :placeholder="placeholder" :disabled="disabled" clearable>
      <el-option
        v-for="option in options"
        :key="option.value"
        :label="option.label"
        :value="option.value"
        :disabled="option.disabled"
      />
    </el-select>
  </el-form-item>
</template>
```

## 要点

- 表单项组件只封装输入结构，不直接提交表单。
- 校验规则建议由父级 `el-form` 统一维护。
- 选项数据可由父级通过 props 传入，避免组件直接耦合接口。
- 如果涉及防抖远程搜索，应先调用 `/vueuse-functions` 判断是否使用 VueUse。
