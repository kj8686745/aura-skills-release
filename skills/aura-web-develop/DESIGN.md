# 技能设计说明

## 单一正式规范源

`knowledge/PIGX前端开发规范/` 保存最新版 PIGX 正式规范正文和目录层级。页面代码骨架直接读取正式页面模式，不在 `templates/` 维护第二套易漂移副本。

## 分层

- `SKILL.md`：优先级、读取路由、强制工作流和交付要求。
- `knowledge/PIGX前端开发规范/`：最新版正式规范。
- `references/`：消息、注释、Figma、Apifox 等不覆盖正式规范的补充约束。
- `recipes/`：基于真实 Hook 和接口契约的落地流程。
- `checklists/`：开发前、实现中、交付前检查。
- `scripts/`：技能结构与目标项目规则扫描。

## 防漂移

维护技能时运行 `scripts/validate-skill.ps1`，并对比最新版规范源。任何历史示例与最新版正文冲突时，删除或改为正式页面模式入口。
