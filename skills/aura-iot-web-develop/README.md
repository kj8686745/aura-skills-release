# aura-iot-devWeb-develop

`aura-iot-devWeb-develop` 是 Aura IOT / `foundation-dev-web` 项目的业务开发规范技能。

它不是单一提示词，而是一个完整的开发工作流包：

- `SKILL.md`：技能入口和强制工作流。
- `knowledge/`：技能内置规范知识库。
- `templates/`：页面、API、Pinia、公共组件预设模板。
- `references/`：项目画像、组件拆分、CSS/Tailwind、模板与示例分工、技能架构等专题规范。
- `checklists/`：开发前、实现中、验证前清单。
- `recipes/`：hooks、页面模式、VueUse 等落地配方。
- `examples/`：可直接模仿的代码示例。
- `scripts/`：项目扫描、qiankun 验证、Tailwind 主题变量扫描、页面复杂度扫描和技能质量校验脚本。
- `USAGE.md`：使用说明。
- `DESIGN.md`：设计方案。

## 使用原则

1. 新任务先按 `SKILL.md` 判断任务类型。
2. 新页面、新 API、新 Pinia 状态和公共组件必须先查 `templates/`。
3. 样式必须先用 Tailwind；颜色必须绑定 Element Plus 主题变量。
4. 表格、图表、消息、表单必须使用项目 hooks。
5. Vue 组合式逻辑必须调用 `/vueuse-functions` 判断。
6. 新增文件必须按 `references/naming-conventions.md` 使用业务语义命名。
7. 新页面没有命中具体页面模板、没有可参考模板结构时，必须调用 `/frontend-design` 完成页面设计。
8. 页面验证必须使用 `/agent-browser`。

## 快速入口

- 使用说明：[`USAGE.md`](USAGE.md)
- 设计方案：[`DESIGN.md`](DESIGN.md)
- 技能入口：[`SKILL.md`](SKILL.md)
