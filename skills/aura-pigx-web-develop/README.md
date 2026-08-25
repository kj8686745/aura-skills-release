# aura-pigx-web-develop

PIGX 模块联邦（综合端）业务开发规范技能。

当前版本：`1.2.1`（2026-08-14）。

`1.2.1` 限定业务错误提示仅用于新增、编辑、删除等改变服务端状态的操作；只读数据加载不在 `catch` 中弹出消息。

## 权威入口

- 技能执行入口：`SKILL.md`
- 版本标识：`VERSION`
- 最新版正式规范：`knowledge/PIGX前端开发规范/README.md`
- 消息反馈硬约束：`references/message-feedback-guidelines.md`
- 代码注释规范：`references/code-comment-guidelines.md`
- 三阶段检查：`checklists/`

最新版正式规范来自 `aura-pigx-cli/src/template/nexus/docs/PIGX前端开发规范`。技能中的历史模板不得覆盖该规范。

## 两项补充硬约束

1. 业务消息只能使用 `import { useMessage, useMessageBox } from '/@/hooks/message';`，不得直接引入 Element Plus Message/MessageBox 或自行实现消息组件。
2. 新增和修改代码必须同步遵循中文注释规范，重点说明 Why、契约、边界、副作用和生命周期。
