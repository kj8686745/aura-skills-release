# fmap-2d 技能包

`fmap-2d` 是公司 2D 地图业务开发规范技能，用于指导 Agent 在 Vue 3 + Vite + TypeScript 项目中接入 `@fxft/ui-plus`，并统一使用 `FxftMap` 实现地图业务。

当前版本：`1.0.1`。

## 适用场景

- 开发设备点位地图页面。
- 实现点位 Marker、聚合点、信息窗和点击事件。
- 实现车辆、人员、设备轨迹回放。
- 接入热力图展示告警、客流、能耗等密度数据。
- 绘制行政区、园区边界、电子围栏或业务区域。
- 渲染后端返回的 GeoJSON 数据。
- 检查或补齐 `@fxft/ui-plus` 与 `FxftUiPlusResolver` 配置。

## 核心原则

1. 后续 2D 地图业务必须优先检查目标项目是否安装 `@fxft/ui-plus`。
2. 未安装依赖时，不得静默安装，必须先获取用户授权。
3. 地图实现必须使用 `FxftMap`，不得重复封装地图 SDK。
4. 优先按需引入组件和样式，避免无必要的全量注册。
5. 数据进入地图组件前必须完成坐标、轨迹、热力、GeoJSON 的基础校验与归一化。
6. 大量点位使用单一聚合层、稳定业务主键和增量同步；显隐与图标切换只调用公开 API。
7. 缩放、移动、旋转时聚合点必须锚定地图坐标，出现漂移时启用交互过程实时重绘。

## 技能结构

```text
fmap-2d/
├── SKILL.md
├── README.md
├── USAGE.md
├── DESIGN.md
├── references/
├── templates/
├── checklists/
├── recipes/
└── scripts/
```

## 快速入口

- 技能入口：`SKILL.md`
- 依赖安装：`references/ui-plus-installation.md`
- 地图组件指南：`references/map-component-guide.md`
- 业务规则：`references/map-business-rules.md`
- 模板索引：`templates/README.md`
- 验证脚本：`scripts/validate-skill.ps1`

## 示例需求

可以这样触发本技能：

- “开发设备点位地图页面”
- “实现车辆轨迹回放”
- “接入告警热力图”
- “绘制行政区 GeoJSON 边界”
- “检查项目是否已接入 @fxft/ui-plus 的 FxftMap”

## 验证

在 `fmap-2d` 目录下执行：

```powershell
.\scripts\validate-skill.ps1
```

脚本会检查必要文件、关键字符串和技能入口结构。
