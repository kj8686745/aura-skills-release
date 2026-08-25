# aura-pigx-web-develop

PIGX 模块联邦（综合端）业务开发规范技能。

当前版本：`1.2.2`（2026-08-25）。

`1.2.2` 新增 PIGX 自动菜单/按钮权限准备与受控幂等创建流程；表格撑满剩余高度采用 Flex + `el-table--fit`，普通 `el-select` 默认开启搜索。

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
3. 模块联邦配置由本技能主导实现，并在修改前后调用 `aura-pigx-module-federation-check` 做基线和复检。
4. 新业务正式页面、菜单入口或操作按钮需要按 `references/admin-menu-permission-workflow.md` 生成菜单权限清单；仅在明确授权且具备运行时凭据时写入管理端。
