# 技能架构说明

本技能不再只依赖一个 `SKILL.md`，而是采用“入口 + 知识库 + 清单 + 配方 + 脚本”的结构。

## 目录职责

| 目录 | 作用 |
|------|------|
| `SKILL.md` | 技能入口，只放触发规则、强制流程和引用索引 |
| `knowledge/` | 技能内置知识库，维护规范原文和补充资料 |
| `references/` | 项目画像、架构说明、命名空间/qiankun/请求等专题规则 |
| `checklists/` | 开发前、提交前、验证前的检查清单 |
| `templates/` | 预设页面/组件模板，开发新页面时必须先匹配 |
| `recipes/` | 常见任务的落地配方，例如 hooks 补齐、VueUse 选型、页面模式适配 |
| `examples/` | 可复用代码骨架和示例，包含 Tailwind + Element Plus 主题变量示例 |
| `scripts/` | 可执行辅助脚本，例如扫描项目结构/依赖/风险 |

## 使用策略

- 简单业务改动：读取 `SKILL.md` + 对应 checklist。
- 新页面开发：读取 `project-profile.md` + `page-patterns.md` + 对应页面模式知识库文档。
- 表格/图表/弹窗开发：读取 `hooks-standards.md`。
- DOM、浏览器 API、防抖节流、异步状态：调用 `/vueuse-functions`，再读取 `vueuse-decision-guide.md`。
- 复杂任务：先调用 `/planning-with-files-junmoxiao`，再按清单推进。
