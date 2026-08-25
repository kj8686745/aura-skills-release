# 实现检查清单

## 组件使用

- [ ] 地图页面使用 `FxftMap` 或 `fxft-map`。
- [ ] 没有自行引入高德、百度、Mapbox、OpenLayers 等地图 SDK。
- [ ] 没有重复实现 `FxftMap` 已提供的点位、聚合、轨迹、热力、绘制、GeoJSON 能力。
- [ ] 通过 `ref` 调用 `FxftMap` 公开 Exposes。

## 依赖接入

- [ ] 已复用目标项目现有包管理器。
- [ ] 已复用或补齐 `FxftUiPlusResolver`。
- [ ] 没有覆盖已有 Vite 插件配置。
- [ ] 未将私有 registry 地址写入业务代码。

## 地图数据

- [ ] 坐标已归一化为 `lon` / `lat`。
- [ ] 无效坐标已过滤。
- [ ] 点位 id 稳定。
- [ ] 点位 id 使用真正唯一的业务主键；资产场景优先 `assetId`，未误用可能重复的设备 ID/编码。
- [ ] 图层名有业务语义。
- [ ] 轨迹有效点不少于 2 个。
- [ ] 轨迹图层显示/隐藏使用 `showTrackLayer()` / `hideTrackLayer()`，没有通过清空或重绘轨迹实现显隐。
- [ ] 隐藏轨迹图层时不会清空轨迹、重置进度；需要暂停播放时使用 `hideTrackLayer()` 默认暂停行为或显式 `pauseTrack()`。
- [ ] 热力点包含权重值。
- [ ] GeoJSON 渲染前已校验结构。
- [ ] 外部状态需要切换交互绘制样式时，未绘制图形通过 `setDrawSymbol` 更新后续样式。
- [ ] 外部状态需要切换已有可编辑图形样式时，通过 `initDraw(geojson, { symbol })` 重新回显。

## 业务逻辑

- [ ] 地图事件回调保持轻量。
- [ ] 复杂请求或保存逻辑拆到业务方法、API 模块或组合式函数。
- [ ] 空数据场景有清理图层或空状态处理。
- [ ] 单个或少量点位移除优先使用 `clearPointById`，没有通过整层重绘替代点位删除。
- [ ] 同一实体只进入一个聚合图层，没有用报警层、设备层重复渲染和重复计数。
- [ ] 整层显隐使用 `setPointLayerVisible`，分类显隐使用 `setPointVisible`，图标切换使用 `updatePointSymbol`。
- [ ] 业务代码没有访问 `_layer`、`_clusterLayerMap` 等地图私有字段。
- [ ] 业务代码没有访问 `_options`、`_drawTool`、`_geometry` 等绘制实现私有字段。
- [ ] 点位范围变化按稳定 id 增量同步，没有每次全量 `clear: true`。
- [ ] 地图加载和初始数据通过同一个幂等入口同步，没有重复追加同一批点位。
- [ ] 缩放、移动、旋转时聚合点不贴屏幕漂移；需要时已启用三个 `forceRenderOn*` 选项。
- [ ] 全部 marker 可隐藏时已验证恢复行为；若出现中心跳动或 `getMin`，已设置 `animation: false`。
- [ ] 刷新数据时不会叠加脏图层。

## 代码风格

- [ ] Vue 页面优先使用 `<script setup>`。
- [ ] 注释和用户可见说明使用简体中文。
- [ ] 新增类型命名具备业务语义。
- [ ] 没有把 token、Cookie、密码写入代码。
