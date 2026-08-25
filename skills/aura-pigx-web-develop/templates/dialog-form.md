# 弹窗表单模板入口

弹窗表单不在本文件重复维护代码骨架。开发前必须完整读取：

- `../knowledge/PIGX前端开发规范/页面模式/弹窗表单.md`
- `../knowledge/PIGX前端开发规范/工程与代码生成规范.md`
- `../knowledge/PIGX前端开发规范/组件复用与公司基础组件库规范.md`
- `../references/message-feedback-guidelines.md`
- `../references/code-comment-guidelines.md`

以最新版 `form.vue` 骨架为准：通过 `defineExpose({ openDialog })` 打开，提交期间防重复，成功后关闭并触发 `refresh`。

新建或修改普通 `el-select` 时默认添加 `filterable`；仅用户明确关闭或组件不兼容时例外。

消息提示只能使用：

```ts
import { useMessage, useMessageBox } from '/@/hooks/message';
```
