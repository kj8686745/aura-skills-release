# Aura Skills Release

这是福信富通技能的发布仓库，只包含已审核、可供安装的技能版本；开发源码、未发布变更和维护资料不在此仓库中。

## 安装

使用 npx skills 安装指定技能：

```powershell
npx skills add kj8686745/aura-skills-release --skill <技能名称> --global --yes
```

更新已安装技能：

```powershell
npx skills update <技能名称> --global --yes
```

## 已发布技能

| 技能 | 版本 | 说明 |
| --- | --- | --- |
| aura-pigx-module-federation-check | 1.0.0 | 自动识别 Vue 3 + Vite 项目属于 PIGX 综合端、模块联邦生产端或消费端，并检查 PIGX 综合端的模块联邦身份、依赖、Vite 配置、shared singleton、运行时外壳、i18n、样式、静态资源和构建产物。用于检查、评审、验收或排查 aura-pigx-cli 综合端及其派生项目的模块联邦代码与配置；首版识别到生产端或消费端后只报告类型和证据，不执行专项审计。 |

发布清单见 [manifest.json](./manifest.json)。
