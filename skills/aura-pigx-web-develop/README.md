# aura-pigx-web-develop

PIGX 模块联邦（综合端）业务开发规范技能。

当前版本：`1.2.9`（2026-08-27）。

`1.2.9` 增加外部技能依赖预检：调用任意其它技能前检查是否安装，缺失时提示用户，只有明确授权后才能安装。

## 权威入口

- 技能执行入口：`SKILL.md`
- 版本标识：`VERSION`
- 最新版正式规范：`knowledge/PIGX前端开发规范/README.md`
- 消息反馈硬约束：`references/message-feedback-guidelines.md`
- 代码注释规范：`references/code-comment-guidelines.md`
- 三阶段检查：`checklists/`

最新版正式规范来自 `aura-pigx-cli/src/template/nexus/docs/PIGX前端开发规范`。技能中的历史模板不得覆盖该规范。

## 补充硬约束

1. 业务消息只能使用 `import { useMessage, useMessageBox } from '/@/hooks/message';`，不得直接引入 Element Plus Message/MessageBox 或自行实现消息组件。
2. 新增和修改代码必须同步遵循中文注释规范，重点说明 Why、契约、边界、副作用和生命周期。
3. 模块联邦配置由本技能主导实现，并在修改前后调用 `aura-pigx-module-federation-check` 做基线和复检。
4. 新业务正式页面、菜单入口或操作按钮需要按 `references/admin-menu-permission-workflow.md` 生成菜单权限清单；仅在明确授权且具备运行时凭据时写入管理端。
5. 使用方式与提示词示例见 [`USAGE.md`](USAGE.md)。
6. 所有业务表单必须使用 `/@/hooks/form` 的 `useForm`，不得在页面中重复实现表单重置和历史校验清理。
7. 用户可见业务页面统一调用 `$frontend-design` 做视觉方向、令牌和实现后自评；纯后端、隐藏页和组件修复不触发。
8. 调用任意其它技能前检查当前可用技能列表；缺失时提示用途、影响和安装选择，未经明确授权不得安装。
