# 查询表格页模板入口

查询表格页不在本文件重复维护代码骨架。开发前必须完整读取：

- `../knowledge/PIGX前端开发规范/页面模式/查询表格页.md`
- `../knowledge/PIGX前端开发规范/工程与代码生成规范.md`
- `../knowledge/PIGX前端开发规范/样式布局与静态资源规范.md`
- `../references/message-feedback-guidelines.md`
- `../references/code-comment-guidelines.md`

直接以最新版页面模式的完整骨架为基线，并根据当前业务域相邻页面、真实 `useTable(state)` 类型和接口契约替换占位内容。

不得恢复旧式 `const { state } = useTable(...)` 或 `const { message, messageBox } = useMessage()`。
