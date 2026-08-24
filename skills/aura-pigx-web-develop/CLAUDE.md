# CLAUDE.md

维护或使用本技能时先读取 `SKILL.md`。

## 最高优先级

`knowledge/PIGX前端开发规范/` 是技能内最新版正式规范。当前项目源码和类型优先于历史示例；其他 references、recipes、templates 只能补充，不能覆盖正式规范。

## 强制规则

- 所有文档、注释和说明使用简体中文与 UTF-8 无 BOM。
- 项目内部路径使用 `/@/`。
- 请求统一走 `/@/utils/request`。
- 业务消息只从 `/@/hooks/message` 导入 `useMessage`、`useMessageBox`。
- 禁止业务代码直接引入 Element Plus Message/MessageBox 或自行实现消息组件。
- 代码注释遵循 `references/code-comment-guidelines.md`。
- 查询表格按真实 `useTable(state)` 签名实现，不使用旧模板返回值。
- 模块联邦、路由菜单、组件、样式和资源按最新版专项规范执行。

修改技能后运行 `scripts/validate-skill.ps1`。
