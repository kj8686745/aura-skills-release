# FxftMap 在 Aura 业务中的接入

用于在 Aura 页面中使用 `@fxft/ui-plus` 的 `FxftMap`：完成组件解析与样式、初始化 Props、实例就绪及业务调用。地图专项能力仍调用可用的 `fmap-2d`：监控点位读点位/聚合与增量同步资料，设备详情读组件与坐标归一化资料，位置选择读“地图选点”，轨迹等按对应场景加载。不要复制底层 SDK。来源与验证版本见[来源记录](fxft-map-source.json)，普通业务任务无需加载该记录。

## 组件接入与最小示例

先核对 `@fxft/ui-plus` 的声明、锁文件和实际安装版本，以及项目既有 `FxftUiPlusResolver` 和 JS/CSS 按需解析。IoT 参考项目使用 `import FxftUiPlusResolver from '@fxft/ui-plus/resolver'`，供 `Components` 解析组件，也供 `auraOptimizeDeps` 扫描实际预构建入口；沿用目标项目配置，缺失时按专项安装/Resolver资料处理，不全量注册或另接 SDK。

以下演示核心配置初始化和普通单点选址；仅展示地图时可省略 `map-click` 及选点状态。父容器须在页面布局中取得有效高度，不能只给未知高度父级下的子元素写 `height: 100%`。

```vue
<template>
  <div class="location-map">
    <FxftMap
      v-if="mapConfigReady"
      ref="mapRef"
      v-bind="mapInitOptions"
      @load="handleMapLoad"
      @map-click="handleMapClick" />
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, reactive, ref } from 'vue';
import { loadMapConfig, type MapConfig } from '@fxft/aura-web-kit/hooks/map-config';

const mapRef = ref<any>(null); // 组件实例，仅调用已验证的公开方法
const mapConfigReady = ref(false); // 配置完成后才创建组件
const mapLoaded = ref(false); // load 后才允许绘点
const mapInitOptions = reactive<Partial<Pick<MapConfig, 'center' | 'zoom' | 'defaultLayer' | 'baseLayers'>>>({});
const selectedLocation = ref<{ lon: number; lat: number } | null>(null); // 实际提交字段按业务接口映射
let disposed = false; // 卸载后不回写配置

const prepareMap = async () => {
  const { center, zoom, defaultLayer, baseLayers } = await loadMapConfig();
  if (disposed) return;
  Object.assign(mapInitOptions, { center, zoom, defaultLayer, baseLayers });
  mapConfigReady.value = true;
};

const handleMapLoad = () => {
  mapLoaded.value = true;
};

const handleMapClick = (payload: any) => {
  if (!mapLoaded.value) return;
  const lon = Number(payload?.coordinate?.x);
  const lat = Number(payload?.coordinate?.y);
  if (!Number.isFinite(lon) || !Number.isFinite(lat) || lon < -180 || lon > 180 || lat < -90 || lat > 90) return;
  selectedLocation.value = { lon, lat };
  mapRef.value?.addPoint?.(
    { id: 'selected-location', lon, lat },
    { clear: true, cluster: false, enableClick: false },
    'locationPickerMarkerLayer'
  );
};

onBeforeUnmount(() => {
  disposed = true;
  mapLoaded.value = false;
});
void prepareMap(); // 依赖应用已绑定请求；初始化错误沿页面既有错误态处理
</script>

<style scoped>
.location-map {
  height: 100%;
  min-height: 0;
}
</style>
```

选点通过 `coordinate.x/y` 读取经纬度，固定 ID + 独立图层 + `clear: true` 保持单 marker，默认 marker 无需另传图标。回填已有坐标、地址搜索与鼠标选点应汇入同一坐标/marker同步方法，等组件 `load` 后执行；不使用 `startDraw('point')` 或 `draw-end`。完整坐标归一化、公开 Exposes 与尺寸变化处理按 `fmap-2d`，本例不承担完整表单提交流程。

## 设备位置与平台兜底接入示例

设备详情业务明确允许缺坐标兜底时，沿用上例的模板、实例、初始化选项与卸载保护，去掉 `@map-click` 及选点状态，以下替换 `prepareMap`、`handleMapLoad`，新增设备数据与同步入口。详情加载/切换前将 `deviceDataReady` 设为 false；成功后把真实字段归一写入 `deviceCoordinate`、置 true 并调用 `syncDevicePoint()`，失败保持错误态。地图先加载或数据先返回都走同一入口。仅展示有效坐标或使用空态的页面不套用此兜底策略。

```ts
const deviceCoordinate = ref<{ lon: number; lat: number } | null>(null);
const deviceDataReady = ref(false); // 区分详情尚未返回与详情确实没有坐标
const fallbackCenter = ref<MapConfig['fallbackCenter'] | null>(null);

const syncDevicePoint = () => {
  if (!mapLoaded.value || !deviceDataReady.value || !fallbackCenter.value) return;
  const point = deviceCoordinate.value;
  const valid = point && Number.isFinite(point.lon) && Number.isFinite(point.lat)
    && point.lon >= -180 && point.lon <= 180 && point.lat >= -90 && point.lat <= 90;
  const coordinate = valid ? point : fallbackCenter.value; // 此设备详情明确允许无坐标兜底
  mapRef.value?.addPoint?.(
    { id: 'device-detail-location', lon: coordinate.lon, lat: coordinate.lat },
    { clear: true, cluster: false, enableClick: false },
    'deviceDetailMarkerLayer'
  );
};

const prepareMap = async () => {
  const config = await loadMapConfig();
  if (disposed) return;
  const { center, zoom, defaultLayer, baseLayers } = config;
  fallbackCenter.value = config.fallbackCenter; // 不用 center 冒充业务兜底
  Object.assign(mapInitOptions, { center, zoom, defaultLayer, baseLayers });
  mapConfigReady.value = true;
};

const handleMapLoad = () => {
  mapLoaded.value = true;
  syncDevicePoint();
};
```

## 配置入口与字段

复用 `@fxft/aura-web-kit/hooks/map-config` 的 `loadMapConfig()`，先核对目标项目实际安装包支持该公开入口。应用请求初始化处绑定一次 `configureMapRequest(request)`；已有 `/@/config/aura/request` 绑定时直接复用，不在页面重复绑定，不另建 HTTP/认证栈或直接请求全局配置接口。

| 核心配置 | 源字段 | 公共结果及消费位置 |
| --- | --- | --- |
| 默认底图 | `sysMap` | `defaultLayer`、`baseLayers` → `FxftMap` 同名 Props |
| 地图中心默认经纬度 | `sysMapCenter` | `center` → `FxftMap.center`，表示初始视图中心 |
| 地图打点兜底经纬度 | `sysMapFallbackCenter` | `fallbackCenter`，仅在业务明确允许缺失坐标兜底时使用 |
| 地图初始缩放值 | `sysMapScaling` | `zoom` → `FxftMap.zoom` |
| 高德 Web 服务 Key | `sysMapAmapKey` | `amapKey`，本次必接示例不需要，明确排除必接及通过门禁 |
| 坐标系元数据 | `sysMapCsys` | `csys`，按需用于坐标转换；不要求页面增加配置项 |

公共服务负责解析、底图别名与底图集合、坐标和缩放归一及默认回退。页面消费返回值，不复制映射表、默认经纬度或缩放上下限，也不照搬配置编辑面板的本地默认值和校验范围。无效的打点兜底配置由公共服务回退到 `center`；它与初始视图中心保持不同职责。

## 挂载与业务操作时机

先 `await loadMapConfig()`，显式取 `center`、`zoom`、`defaultLayer`、`baseLayers` 写入地图初始化选项，再开放 `v-if` 挂载 `FxftMap`。不要先用页面硬编码值创建地图，再期待初始化 Props 必然热更新；也不要把整个 `MapConfig` 直接 `v-bind`，`fallbackCenter`、`csys`、`amapKey` 不是本接入所需的地图初始化 Props。

配置就绪仅表示允许挂载；必须另等 `FxftMap` 的 `load` 事件，再调用点位、轨迹、`flyTo` 等公开方法。初始业务数据与地图加载按专项规则汇入幂等同步入口。卸载或目标变化后的异步回写沿项目现有状态所有权处理。

有有效业务坐标时，是否定位到业务对象由页面需求决定；未提供坐标时，先决定该场景应展示空态、过滤无效点，还是使用配置兜底。不能将所有缺坐标资产批量伪装成同一真实位置，不能用 `fallbackCenter` 无条件替换系统视图 `center`。

跨坐标系数据按真实需求读取 `csys`，核对数据源坐标系及实际安装的 `@fxft/aura-web-kit/utils/coordinate` 公开类型和方法（如 `transformCoordinate`、`toAmapCoordinate`、`fromAmapCoordinate`）。不默认开启 `gaodeCorrection`，避免重复纠偏。高德 Web 服务 Key 不需要接入本次地图门禁，不因未读、未传或缺 Key 本身判地图门禁失败；实际地址服务仍按需求验收功能，不因此豁免真实功能失败；不硬编码或在交付记录输出真实 Key。

## 默认、异常与刷新

已验证的 web-kit `1.10.4` 中，未绑定请求实例会拒绝加载，应修复初始化绑定或按页面现有错误态呈现。全局配置请求失败则由公共服务返回默认配置；成功返回 `MapConfig` 不证明后台读取成功，页面不重复覆盖默认逻辑。

该版本在公共服务实例内缓存配置 Promise，合并并发调用，失败后的默认结果也缓存。再次打开页面或再次调用 `loadMapConfig()` 不保证重新请求，且没有公开自动刷新或重试 API。系统配置保存后需要刷新应用或依赖目标版本已验证的更新机制；不擅自添加轮询、清缓存入口或借重新绑定请求函数实现刷新。

## 按变更验收

所有地图功能自检均须核对实际使用 `FxftMap`、平台四项初始化 Props 及适用的 `fallbackCenter` 消费；已确认未接、假接或硬编码覆盖为偏差，缺证为未证实，该地图项及覆盖它的自检不得通过。高德 Web 服务 Key 明确排除必接及通过门禁；无地图与纯注释保持原范围。审查侧使用其随包 FxftMap 门禁，不依赖跨安装目录引用。

- 首次进入、重开及实际支持的刷新方式下，核对四项初始化 Props 来自公共结果，底图与中心/缩放未被页面常量覆盖。
- 分别核对有效业务坐标与缺失坐标的处理，配置中心和打点兜底各用其位；地址服务或坐标转换仅在本次涉及时验证。
- 核对配置加载与地图 `load` 两个阶段，以及请求失败默认行为、未绑定错误和缓存对本次需求的影响。仅在授权范围内执行必要场景，不为验证修改全局系统配置；静态调用存在不能代替实际地图显示与交互验证。
