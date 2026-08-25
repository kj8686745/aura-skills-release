<script setup lang="ts">
import { reactive, ref } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import { useMessage } from '@/hooks/message'

interface FormModel {
  name: string
  remark: string
}

const visible = defineModel<boolean>('visible', { default: false })

const emit = defineEmits<{
  success: []
}>()

const message = useMessage()
const formRef = ref<FormInstance>()
const submitting = ref(false)
const form = reactive<FormModel>({
  name: '',
  remark: '',
})

const rules: FormRules<FormModel> = {
  name: [{ required: true, message: '请输入名称', trigger: 'blur' }],
}

const resetForm = () => {
  form.name = ''
  form.remark = ''
  formRef.value?.clearValidate()
}

const handleSubmit = async () => {
  await formRef.value?.validate()
  submitting.value = true
  try {
    // 示例：真实项目必须调用 src/api/ 中的接口
    message.success('保存成功')
    emit('success')
    visible.value = false
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <el-dialog v-model="visible" title="示例表单" width="520px" destroy-on-close @closed="resetForm">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="88px">
      <el-form-item label="名称" prop="name">
        <el-input v-model="form.name" placeholder="请输入名称" clearable />
      </el-form-item>
      <el-form-item label="备注" prop="remark">
        <el-input v-model="form.remark" type="textarea" placeholder="请输入备注" />
      </el-form-item>
    </el-form>

    <template #footer>
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
    </template>
  </el-dialog>
</template>
