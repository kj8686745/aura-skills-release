# 命名规范

## 总原则

新增文件、目录、路由、store、hooks、组件和 API 模块时，必须先根据业务语义命名，再考虑技术类型；不得只按接口路径片段、临时变量或通用词命名。

命名决策顺序：

1. **业务域**：设备、终端、报表、用户、权限、告警、工单等。
2. **业务对象**：终端数量统计、在服终端、平台配置、角色授权等。
3. **功能动作**：查询、下载、保存、删除、同步、导入、导出等。
4. **技术类型**：page、store、hook、dialog、drawer、card、table 等，仅作为补充。

## API 文件命名

API 文件必须体现业务域和业务对象，不能只取接口路径中的泛化片段。

| 场景 | 推荐命名 | 不推荐命名 |
|------|----------|------------|
| 终端数量统计报表下载 | `device-statistics-report.ts` | `online.ts`、`api.ts`、`download.ts` |
| 设备列表/详情/保存 | `device.ts` 或 `device-management.ts` | `index.ts`、`common.ts` |
| 用户权限 | `user-permission.ts` | `security.ts`（除非模块确实覆盖整个 security 域） |
| 平台配置 | `platform-config.ts` | `config.ts`（过泛时不允许） |

API 函数命名必须采用「动作 + 业务对象」：

- `downloadMergedDeviceNumStatistics`
- `queryDevicePage`
- `savePlatformConfig`
- `deleteDevice`

禁止：`api1`、`query`、`fetchData`、`downloadFile`、`getList` 等脱离业务的命名。

## 页面目录与页面文件命名

页面目录必须体现业务域和页面用途。

```text
src/views/<module>/<page>/index.vue
```

推荐：

```text
src/views/device/statistics-report/index.vue
src/views/device/management/index.vue
src/views/platform/config/index.vue
```

当当前项目仍是轻量路由、未形成模块目录时，可以临时使用顶层页面文件，但文件名仍必须体现业务：

```text
src/views/DeviceStatisticsReportView.vue
```

禁止：

- `Page.vue`
- `Report.vue`（除非模块内已明确上下文）
- `OnlineView.vue`
- `DownloadView.vue`
- `TestView.vue`

## 路由命名

路由 `path`、`name`、`meta.title` 必须保持业务一致：

```ts
{
  path: '/device-statistics-report',
  name: 'device-statistics-report',
  meta: { title: '终端数量统计报表' },
}
```

禁止：

- 路由 name 使用 `page`、`list`、`detail` 这类无业务语义名称。
- path 与页面业务不一致。

## 组件命名

局部组件必须体现当前页面中的职责：

- `SearchPanel.vue`
- `StatisticCard.vue`
- `ReportDownloadCard.vue`
- `DeviceStatusTag.vue`

公共组件放在 `src/components/<ComponentName>/index.vue`，组件名必须体现可复用能力，而不是具体页面接口：

- 推荐：`MetricCard`、`ReportDownloadCard`、`QueryPanel`
- 禁止：`DeviceApiCard`、`PageBox`、`MyComponent`

## Pinia Store 命名

Store 文件名和 store id 必须使用业务域：

```ts
// src/stores/device-statistics.ts
export const useDeviceStatisticsStore = defineStore('deviceStatistics', {})
```

禁止：

- `useDataStore`
- `usePageStore`
- `useCommonStore`（除非真的维护全局公共状态）

## Hooks / Composables 命名

业务组合式函数使用 `use + 业务对象 + 能力`：

- `useDeviceStatisticsDownload`
- `useDeviceQuery`
- `useReportExport`

禁止：

- `useData`
- `usePage`
- `useRequest`（除非是请求底层封装）

## 样式文件与目录命名

页面模块样式目录使用固定 `styles/`，内部文件按区块命名：

```text
styles/
├── index.scss
├── search.scss
├── table.scss
├── report-card.scss
└── chart.scss
```

禁止：

- `style1.scss`
- `common.scss`（页面私有样式里过泛）
- `aaa.scss`

## 交付要求

凡新增文件或命名明显影响后续维护时，交付说明必须写明命名依据：

- API 模块为什么叫这个名称。
- 页面目录/路由为什么这样命名。
- 组件、store、hooks 是否根据业务职责命名。
