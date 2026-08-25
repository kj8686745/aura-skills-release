# 模板：弹窗表单

## 适用场景

- 页面存在新增、编辑、复制、配置等弹窗表单。

## 强制规则

- 只有存在弹窗表单需求时才创建 `form.vue`。
- 表单重置必须使用 `src/hooks/form.ts` 的 `useForm`。
- 消息提示和确认框必须使用 `src/hooks/message.ts`。
- 复杂联动、动态字段、分组区域必须按职责拆局部组件。
- 表单 props/emits 必须有类型定义。
- 弹窗打开方法必须通过 `defineExpose` 暴露，例如 `openDialog`。
