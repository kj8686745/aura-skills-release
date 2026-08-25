# 地图模板索引

涉及 2D 地图页面时，先按业务场景选择模板，再结合目标项目结构和真实接口调整。

## 模板列表

| 场景 | 模板 | 适用需求 |
|---|---|---|
| 基础地图 | `fxft-map-basic-page.md` | 只需要加载地图、底图切换、地图工具栏 |
| 点位与聚合 | `fxft-map-points.md` | 设备点位、告警点位、人员点位、聚合展示 |
| 轨迹回放 | `fxft-map-track.md` | 车辆轨迹、人员轨迹、设备移动轨迹 |
| 热力图 | `fxft-map-heat.md` | 告警密度、客流密度、能耗密度 |
| 绘制与 GeoJSON | `fxft-map-draw-geojson.md` | 电子围栏、行政区边界、园区边界、GeoJSON 渲染 |

## 使用顺序

1. 先检查目标项目是否安装 `@fxft/ui-plus`。
2. 再检查 `FxftUiPlusResolver` 或全量注册配置。
3. 按业务场景读取对应模板。
4. 按 `recipes/map-data-normalization.md` 适配后端数据。
5. 按 `checklists/implementation.md` 和 `checklists/validation.md` 验证。

## 模板调整原则

- 保留 `FxftMap` 作为地图组件。
- 保留稳定图层名，按业务语义改名。
- 坐标字段进入组件前统一为 `lon` / `lat`。
- 不引入其它地图 SDK。
- 事件处理器保持轻量，复杂逻辑拆成业务方法。
