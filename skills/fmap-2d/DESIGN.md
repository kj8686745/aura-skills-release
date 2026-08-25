# fmap-2d 设计方案

## 设计目标

`fmap-2d` 的目标不是沉淀一份长文档，而是成为 Agent 可执行的 2D 地图业务开发工作流包。

它需要解决以下问题：

1. 让 Agent 在遇到 2D 地图需求时，优先检查 `@fxft/ui-plus`。
2. 让 Agent 使用组件库已有的 `FxftMap` 能力，而不是重新封装地图 SDK。
3. 将安装、接入、业务规则、模板、验证拆分成可按需读取的资料。
4. 删除仅供阅读的原始 `docs/` 资料后，技能仍然自包含、可执行。

## 架构选择

本技能采用以下结构：

```text
入口 SKILL.md
  ↓
references：项目画像、安装规则、组件指南、业务规则
  ↓
templates：地图场景代码模板
  ↓
recipes：安装接入、业务流程、数据归一化配方
  ↓
checklists：开发前、实现中、交付前清单
  ↓
scripts：结构和关键词校验
```

## 为什么入口轻量

`SKILL.md` 会在技能触发时优先进入上下文。如果把完整 Props、Events、Exposes 和所有代码示例放在入口，会导致：

- 上下文过重。
- 后续维护难度高。
- Agent 难以快速定位当前任务所需资料。

因此入口只保存：

- 触发范围。
- 任务类型到资料文件映射。
- 强制工作流。
- 硬性约束。
- 交付格式。

详细内容分散到 `references/`、`templates/`、`recipes/`。

## 为什么删除 docs

原始 `docs/SKILL.md` 与 `docs/MAP.md` 是临时阅读资料。用户明确说明技能中不用保留这两个文件。为了避免后续 Agent 依赖原始资料而不是成品技能结构，本技能将必要知识提炼到正式目录中，并删除 `docs/`。

## 资料分层

### references

维护稳定规则与组件 API 摘要：

- `project-profile.md`：技术栈与适用范围。
- `ui-plus-installation.md`：安装、按需引入、resolver 配置。
- `map-component-guide.md`：`FxftMap` 高频 Props、Events、Exposes。
- `map-business-rules.md`：坐标、图层、点位、轨迹、热力、GeoJSON 业务规则。

### templates

维护可复制改造的 Vue 3 `<script setup>` 模板：

- 基础地图。
- 点位与聚合。
- 轨迹回放。
- 热力图。
- 绘制与 GeoJSON。

### recipes

维护从真实项目落地的操作步骤：

- 如何检查并接入 `@fxft/ui-plus`。
- 如何从需求拆解到地图实现。
- 如何做坐标和地图数据归一化。

### checklists

将强制规则变成可验证清单，减少遗漏。

### scripts

`validate-skill.ps1` 用于静态检查技能结构和关键字符串，确保技能包可迁移、可复查。

## 关键约束设计

- **依赖安装授权**：安装依赖属于外部变更，必须用户授权。
- **组件库优先**：`FxftMap` 已有能力不重复实现。
- **公开 API 优先**：优先使用 `FxftMap` Exposes，不直接访问底层地图实例。
- **数据适配前置**：坐标、轨迹、热力、GeoJSON 在进入组件前先归一化和过滤。
- **验证闭环**：交付时必须汇报依赖、resolver、页面行为和未验证风险。
