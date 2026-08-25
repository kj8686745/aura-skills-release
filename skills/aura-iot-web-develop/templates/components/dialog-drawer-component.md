# 模板：弹窗 / 抽屉组件

## 适用场景

- 新增或编辑弹窗。
- 详情抽屉。
- 授权、绑定、确认类交互容器。
- 主页面过重，需要把弹窗表单拆出。

## 弹窗模板

```vue
<script setup lang="ts">
import { reactive, ref } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import { useMessage } from '@/hooks/message'

export interface DemoFormModel {
  id?: string
  name: string
  status: string
}

const visible = defineModel<boolean>('visible', { default: false })

const emit = defineEmits<{
  success: []
}>()

const message = useMessage()
const formRef = ref<FormInstance>()
const submitting = ref(false)

const form = reactive<DemoFormModel>({
  name: '',
  status: '',
})

const rules: FormRules<DemoFormModel> = {
  name: [{ required: true, message: '请输入名称', trigger: 'blur' }],
}

const resetForm = () => {
  form.id = undefined
  form.name = ''
  form.status = ''
  formRef.value?.clearValidate()
}

const openDialog = (row?: Partial<DemoFormModel>) => {
  resetForm()
  Object.assign(form, row || {})
  visible.value = true
}

const handleClose = () => {
  visible.value = false
}

const handleSubmit = async () => {
  await formRef.value?.validate()
  submitting.value = true
  try {
    // TODO: 调用 src/api/ 中的保存接口
    message.success('保存成功')
    emit('success')
    handleClose()
  } finally {
    submitting.value = false
  }
}

defineExpose({ openDialog })
</script>

<template>
  <el-dialog v-model="visible" title="编辑信息" width="560px" destroy-on-close @closed="resetForm">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="96px">
      <el-form-item label="名称" prop="name">
        <el-input v-model="form.name" placeholder="请输入名称" clearable />
      </el-form-item>
    </el-form>

    <template #footer>
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
    </template>
  </el-dialog>
</template>
```

## 抽屉模板

```vue
<script setup lang="ts">
const visible = defineModel<boolean>('visible', { default: false })

withDefaults(
  defineProps<{
    title?: string
  }>(),
  {
    title: '详情',
  },
)
</script>

<template>
  <el-drawer v-model="visible" :title="title" size="640px" destroy-on-close>
    <slot />

    <template v-if="$slots.footer" #footer>
      <slot name="footer" />
    </template>
  </el-drawer>
</template>
```

## 要点

- 弹窗显示状态建议使用 `defineModel<boolean>('visible')`。
- 新增/编辑弹窗应暴露 `openDialog`，由父页面传入编辑数据。
- 消息提示使用 `src/hooks/message.ts` 的 `useMessage` / `useMessageBox`。
- 接口调用必须走 `src/api/`。
- 详情抽屉只展示数据时，不要把保存逻辑塞入组件。
