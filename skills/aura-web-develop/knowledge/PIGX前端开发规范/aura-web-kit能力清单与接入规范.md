# aura-web-kit 能力清单与接入规范

## 一、版本与选用原则

本目录的公共包验证基线：`@fxft/aura-web-kit@1.9.6`。核对日期：2026-11-03；依据 IoT 验证项目实际安装发布包的 `package.json.exports` 与对应 `dist/*.d.ts`，覆盖 **115 个公开子入口**，逐项核对声明与运行入口文件存在。目标项目仍须核对依赖声明、锁文件与实际安装一致；不把源码仓库的新能力或任意更高版本自动视为可用。本轮仅更新 web-kit 目录基线；原框架 **1.2.0** 的其他配套记录（2026-10-21）继续保留：`@fxft/aura-ui@1.1.2`、Element Plus `2.14.6`、VueUse `15.0.0`、Node.js `>=22.12.0`、TypeScript `5.9.3`、ESLint `8.57.1`、typescript-eslint parser/plugin `8.46.1`，不据此宣称本轮重新验证这些依赖。

新增或修改公共 TS 时，先按场景查表，再读相应入口的声明和实现。包没有根入口；使用 `@fxft/aura-web-kit/<子路径>`，不引用 `src/`、`dist/` 或未导出的内部模块。表中列出主要导出用于检索，具体参数和完整导出以该版本声明为准。

- 无项目依赖的工具、`useForm`、`usePermissions` 可直接从公共包导入。
- 消息、表格、字典、参数等依赖请求/Pinia/i18n 的 Hook 使用项目已创建的绑定；不要在页面重新创建工厂或误用缺少上下文的底层 Hook。
- 工具、Hook、运行时算法和构建兼容修复若适合跨项目，统一进入 web-kit，显式接收依赖；项目保留实例、环境参数、资源路径和业务逻辑。
- 公共包修改完成对应测试、发布包消费验证、使用项目验证并同步清单；版本升级沿项目发布流程执行。

## 二、业务导入与项目绑定

| 场景                       | 页面/API 使用入口                                 | 绑定职责                                                                                 |
| -------------------------- | ------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| 请求                       | `/@/config/aura/request` 默认导出                 | 项目请求、认证、地图/参数 API 绑定；业务不直接创建 Axios                                 |
| 表格、消息、字典、参数     | `/@/config/aura/index`                            | `useTable`、`useMessage`、`useMessageBox`、`useDict`、`useParam`；共享本项目 auraContext |
| 表单                       | `@fxft/aura-web-kit/hooks/form`                   | `useForm` 与 `FormRef`，无需项目请求                                                     |
| 权限                       | `@fxft/aura-web-kit/hooks/permissions`            | 读取宿主提供的权限上下文，不能自建空权限默认值                                           |
| 登录与用户状态             | `/@/config/aura/account`                          | 登录 API、OAuth、用户 Store                                                              |
| 存储、认证、令牌           | `/@/config/aura/storage`、`auth`、`tokenCheck`    | systemId、退出策略与令牌监测                                                             |
| 图表、下载、混合工具       | `/@/config/aura/echarts`、`download`、`utilities` | 图表空态图片、请求下载及项目资源                                                         |
| 联邦加载、语言、样式       | `/@/config/aura/federation`                       | enhanced runtime、远程 entries、Provider、scope                                          |
| 资源地址                   | `/@/hooks/moduleFederation`                       | 绑定提供方自身 `import.meta.url` 与 remoteEntryName                                      |
| 浏览器属性、事件、构建信息 | `/@/config/aura/browser`                          | 项目环境、Router、构建信息与总线                                                         |
| 路由                       | `/@/router/index`                                 | 项目 Router 和菜单/Store 实例                                                            |

```ts
import request from '/@/config/aura/request';
import { useTable, useDict, useMessage, useMessageBox } from '/@/config/aura/index';
import type { BasicTableProps } from '@fxft/aura-web-kit/hooks/table';
import { useForm } from '@fxft/aura-web-kit/hooks/form';
import { usePermissions } from '@fxft/aura-web-kit/hooks/permissions';
import { handleTree } from '@fxft/aura-web-kit/utils/tree';
```

项目 `src/config/aura/index.ts` 使用 `createAuraFrameworkContext({ request, pinia, getLocale })`，再以 `createTableHook/createMessageHooks/createDictHook/createParamHook` 生成绑定。配置不放入模块级跨应用可变默认对象。

Vite 与 TypeScript 仅保留 `/@` 源码映射；旧 `/@/utils/request`、`/@/hooks/message`、`/@/hooks/form` 等是历史入口，1.2.0 新代码直接引用上表，不新增迁移 alias。本规范只面向 1.2.0，不提供旧路径兼容；迁移需同时完成实例绑定与调用入口。

## 三、公开子入口清单

表内入口统一省略 `@fxft/aura-web-kit` 前缀。运行环境“浏览器”表示运行时入口；其中纯工具可无 DOM 使用，仍需核对签名与依赖。“类型”入口按类型/声明消费。“Node 构建”入口不能进入浏览器依赖图。

### 常用 Hook 与服务

| 公开入口                  | 主要导出或类型                                                                                                                                                   | 用途                                                                                               | 运行环境 / 绑定要求  |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | -------------------- |
| `/api/params`             | `configureParamRequest`                                                                                                                                          | 参数请求适配                                                                                       | 浏览器               |
| `/hooks/common`           | `createCommonHook`                                                                                                                                               | 项目常用工具绑定                                                                                   | 浏览器               |
| `/hooks/map-config`       | `DEFAULT_MAP_CENTER`、`configureMapRequest`、`loadMapConfig`、`loadMapCenter`                                                                                    | 地图配置与请求绑定                                                                                 | 浏览器               |
| `/hooks/form`             | `useForm`、`FormFieldPaths`、`FormAdapter`、`FormRef`、`FormSubmitOptions<T>`、`FormSubmitResult<T>`                                                             | 表单校验、重置、清理校验；返回 `pending/runSubmit` 提交防重能力                                    | 浏览器               |
| `/hooks/permissions`      | `PERMISSION_CONTEXT_KEY`、`createPermissionContext`、`usePermissions`                                                                                            | 权限上下文与权限判断                                                                               | 浏览器               |
| `/runtime`                | `AURA_CONTEXT_KEY`、`createAuraContext`、`captureAuraContext`、`provideAuraContext`                                                                              | 应用上下文与服务契约                                                                               | 浏览器               |
| `/framework`              | `createAuraFrameworkContext`                                                                                                                                     | 框架请求、Pinia、语言服务预设                                                                      | 浏览器；使用项目绑定 |
| `/api/common`             | `createCommonApi`                                                                                                                                                | 字典与参数 API 工厂                                                                                | 浏览器               |
| `/hooks/table`            | `useTable`、`createTableHook`、`BasicTableProps<Row>`、`Pagination`、`TableStyle`、`PageQuery`、`PageResult<Row>`、`OrderItem`、`TableQueryOptions`              | 标准 current/size 分页、排序、查询与单次静默刷新                                                   | 浏览器；使用项目绑定 |
| `/hooks/compatible-table` | `useCompatibleTable`、`createCompatibleTableHook`、`TableProtocol`、`CompatibleTableOptions`、`BasePageQuery`、`BasePageResult<Row>`、`AuraTablePageResult<Row>` | 显式 `base/aura` 分页协议适配，复用 useTable；base 使用 pageNo/pageSize、rows/totalCount/totalPage | 浏览器；使用项目绑定 |
| `/hooks/message`          | `createElementPlusMessageServices`、`useMessage`、`useMessageBox`、`createMessageHooks`                                                                          | 消息、确认框与重复合并                                                                             | 浏览器；使用项目绑定 |
| `/hooks/dict`             | `createDictHook`、`useDict`                                                                                                                                      | 字典查询与缓存                                                                                     | 浏览器；使用项目绑定 |
| `/hooks/param`            | `createParamHook`、`useParam`                                                                                                                                    | 系统参数查询与缓存                                                                                 | 浏览器；使用项目绑定 |
| `/hooks/echarts`          | `isChartDataEmpty`、`useECharts`、`createEChartsHook`                                                                                                            | 图表生命周期、空态与 resize                                                                        | 浏览器；使用项目绑定 |
| `/api/login`              | `LoginTypeEnum`、`LoginErrorEnum`、`SocialLoginEnum`、`createLoginApi`                                                                                           | 登录 API 工厂与枚举                                                                                | 浏览器               |

#### 表单公共契约与版本

业务通过 `@fxft/aura-web-kit/hooks/form` 消费 `useForm`，不复制公共 `form.ts`。原有 `validateForm`、`resetForm`、`clearFormValidate` 三方法按实际操作选用；完整表单无需无条件调用全部方法，查询表单仅重置时也无需凭空增加提交校验。非 Element Plus 动态表单需保留其实际校验协议，不能把“Promise 正常完成且无返回值”硬转为本 Hook 的布尔成功协议。

| 方法                                      | 使用契约                                                                                                                                                  |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `validateForm(formRef)`                   | 整表校验，只有返回 true 才进入写请求；未挂载、返回 false 或异常均不放行                                                                                   |
| `clearFormValidate(formRef, props?)`      | 等待 nextTick 后清理全部或指定字段校验；回填、复用及动态字段变化后按需 await                                                                              |
| `resetForm(formRef, model, initialData?)` | 保持 ref/reactive 模型身份，调用 resetFields 后将原自有可枚举字段置 undefined，再覆盖初值；需要稳定默认值时传完整模型                                     |
| `validateFormFields(formRef, props)`      | 新增字段级校验，返回 Promise<boolean>；复用 validateField，不校验无关字段。支持单字段、字段数组、点路径与分段路径数组；空字段、未挂载、缺能力或失败不放行 |

**当前安装包状态（2026-11-03）**：已安装发布包 1.9.6 的 `/hooks/form` 声明和实现包含 `validateFormFields`、`FormFieldPaths` 及 VueUse 手动结构化克隆重置；`useForm` 还返回 `pending/runSubmit`，提交协议与类型按实际声明使用。本目录不再将这些能力标为未发布；其他消费者仍须核对声明、锁文件、实际包 exports/types 与运行环境，按授权处理升级，不推断旧 1.9.0/1.9.1 包具有相同能力。

字段校验示例仅适用于已安装声明确有该方法的版本：

```ts
const { validateFormFields } = useForm();
if (!(await validateFormFields(formRef, ['startAt', 'plannedRestoreAt']))) return;
// 一个字段由多段路径组成时加外层数组，区别于多个字段名。
const valid = await validateFormFields(formRef, [['rows', '0', 'name']]);
```

字段必须与实际 `el-form-item` prop、挂载条件和规则一致；仅返回 true 不证明拼错或未注册的字段已被校验。公共 Hook 不持有业务请求、详情 ID、权限、提交成功消息、弹窗关闭或列表刷新，校验与请求防重按 [FE-013](工程与代码生成规范.md#五权限表单和国际化)执行。

#### 数据副本与克隆

本节适用于新增的数据克隆及本次明确修改的克隆逻辑，归入 FE-021 公共能力选型，并关联 FE-013/019 的表单实现。对象、数组需要副本时统一通过 VueUse `useCloned` 等已提供能力处理；不新增手写递归、直接 JSON 序列化克隆或另一套 `cloneDeep` 封装。已有公共或项目克隆封装及其现有调用本轮暂不迁移，不因维护普通业务顺带重构；`form.ts` 为本轮明确调整的公共表单实现。

浅拷贝只创建第一层容器，嵌套对象和数组仍共享引用；深拷贝按选定策略隔离支持的数据图。不能根据“调用了 VueUse”就推断所有类型均可无损复制。字段赋值、显式 DTO 组装和把已隔离的数据写入现有模型可使用赋值或 `Object.assign`；这些操作不承诺副本隔离，也不能代替独立编辑草稿的克隆。

| 实际场景                                                    | 统一用法                                                                                                   | 选择与边界                                                                                                             |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 只需第一层快照，嵌套数据明确只读或有意共享                  | `useCloned(source, { manual: true, clone: value => ({ ...toRaw(value) }) })`；数组对应 `[...toRaw(value)]` | 明确标注浅拷贝，不用于会修改嵌套字段的编辑模型；这是 VueUse 的显式 clone 策略                                          |
| 纯 JSON 业务数据的独立副本                                  | `useCloned(source, { manual: true })`，源变化后显式 `sync()`                                               | 默认 JSON 克隆；仅当字段与值完全符合该序列化协议时使用                                                                 |
| 含 `undefined`、`Date`、`Map`、`Set` 或循环引用的结构化数据 | `useCloned(source, { manual: true, clone: value => structuredClone(toRaw(value)) })`                       | 环境须支持 `structuredClone`；`toRaw` 仅解包根层，函数、DOM、显式嵌套 Proxy 等不可克隆数据需在数据边界映射，不静默降级 |
| 详情编辑、取消不得影响原数据                                | 按 ID 读取详情并显式映射 DTO，再由 VueUse 创建独立草稿；打开/切换记录时同步                                | 不把列表行快照作为详情；避免源刷新自动覆盖未提交输入                                                                   |
| 新增表单与重复打开重置                                      | 用完整初值工厂构造业务默认值，再通过公共 `useForm().resetForm` 恢复                                        | 默认值构造不是复制既有数据；公共 Hook 的克隆策略和可用版本见下节，不在各页面重写实现                                   |

`useCloned` 默认对 ref/getter 源建立同步监听，适合确需跟随源更新的派生副本；编辑草稿默认 `manual: true`，只在明确的打开、切换或重载动作中调用 `sync()`。它返回的 `isModified` 是修改标记，不等于当前草稿与源深值不相等，不能单凭它决定保存、关闭或丢弃输入。Composable 在组件 setup 或可清理的作用域中创建；一次性克隆若在重复操作内创建，必须释放其内部监听，不能每次重置累积 watcher。

纯 JSON 草稿示例：

```ts
import { useCloned } from '@vueuse/core';
import { shallowRef } from 'vue';

const source = shallowRef({ name: '', nodes: [] as Array<{ host: string }> });
const { cloned: draft, sync } = useCloned(source, { manual: true });

// 打开时 detail 来自已完成的 ID 详情查询；这里只映射本表单的业务字段。
function fillDraft(detail: { name: string; nodes: Array<{ host: string }> }) {
  source.value = { name: detail.name, nodes: detail.nodes };
  sync();
}
// 修改 draft.value.nodes 不修改 source；取消时不回写详情源。
```

反例：`reactive({ ...defaults })` 被当作嵌套独立编辑模型；`Object.assign(model, defaults)` 后编辑数组污染默认值；对含 Date 的模型使用默认 JSON 克隆而误将日期对象变为字符串；每次点击都创建未清理的 `useCloned`。

验收需按真实类型覆盖：嵌套对象/数组修改不污染源、重复打开恢复默认值、取消不回写详情、源刷新不覆盖手动草稿、特殊类型保持约定含义、不可克隆值不会先清空用户输入。参考 [VueUse useCloned](https://vueuse.org/core/useCloned/)；具体 API 以已安装 VueUse 版本为准。

#### 已加载列表的静默刷新（1.9.6 已发布）

覆盖层仍可见且操作成功需同步背后已加载区域时，使用本次查询的显式选项。web-kit `1.9.6` 的真实签名为 `getDataList(refresh?: unknown, options?: TableQueryOptions): Promise<void>`，`TableQueryOptions` 从 `@fxft/aura-web-kit/hooks/table` 导出，仅含可选 `silent?: boolean`，不是 `useTable` 全局配置。

```ts
// 已确认操作成功，覆盖层仍可见；本调用沿既有业务约定保留当前页。
await getDataList(false, { silent: true });
// 若原业务要求回第一页，首参保留原语义；其余首参（含事件）也会回第一页。
await getDataList(true, { silent: true });
```

`silent: true` 仅在调用时 `dataList` 为非空数组时抑制该区域 Loading，保留已有行与总数直到新响应成功；首次读取或空表回落为正常 Loading，不能宣称覆盖全部初始化状态。失败保留旧数据，并沿 `queryError` / `onQueryError` 反馈；请求序号继续阻止旧响应污染。选项只作用于本次调用，普通查询、分页和排序仍显示正常 Loading，不改变既有选择恢复规则。

使用前核对项目声明、锁文件与实际安装包的类型和实现；本能力已随 `1.9.6` 发布，本目录已按实际安装 `1.9.6` 核对；旧包不因历史清单而获得第二参，也不要求已获授权升级的项目回退。缺能力时如实记录并按任务授权处理依赖，不虚构 API 或复制公共 Hook。

### 请求、认证与存储

| 公开入口            | 主要导出或类型                                                                                                                                                                               | 用途                                       | 运行环境 / 绑定要求  |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ | -------------------- |
| `/http/preset`      | `createFrameworkHttpOptions`                                                                                                                                                                 | 框架请求预设                               | 浏览器；使用项目绑定 |
| `/auth/framework`   | `createFrameworkAuth`                                                                                                                                                                        | 框架认证策略                               | 浏览器；使用项目绑定 |
| `/http/service`     | `createRequestClient`、`AuraQueryFormatOptions`、`AuraQueryFormatTargetOptions`                                                                                                              | Axios 实例工厂与显式 queryFormat 类型      | 浏览器；使用项目绑定 |
| `/storage`          | `STORAGE_KEYS`、`createAuraStorage`                                                                                                                                                          | 按系统隔离的 Local、Session、Cookie        | 浏览器；使用项目绑定 |
| `/http`             | `createAuraRequest`、`createLazyRequest`、`CommonHeaderEnum`、`adaptRequestUrl`、`AuraRequest`、`AuraHttpOptions`、`RequestCrypto`、`AuraQueryFormatOptions`、`AuraQueryFormatTargetOptions` | 请求门面、懒加载、公共头与显式 queryFormat | 浏览器；使用项目绑定 |
| `/http/crypto`      | `encryptRequestText`、`decryptRequestText`、`createApiCrypto`                                                                                                                                | 请求加解密                                 | 浏览器；使用项目绑定 |
| `/auth`             | `REQUEST_AUTH_ERROR_EVENT`、`createAuthController`、`dispatchRequestAuthError`                                                                                                               | 认证错误事件与退出控制                     | 浏览器；使用项目绑定 |
| `/auth/token-check` | `createTokenMonitor`、`useTokenCheck`                                                                                                                                                        | 令牌监测生命周期                           | 浏览器；使用项目绑定 |

#### 查询提交参数格式化（1.9.5 已发布）

算法由纯函数 `formatQueryParams` 承担，独立入口 `@fxft/aura-web-kit/utils/query` 保留给非请求条件构造等场景。业务 API 优先复用项目统一请求实例的显式 `queryFormat`，不逐模块重复导入算法；请求层在 JSON 归一化和加密之前调用公共实现。默认不开启，不按 HTTP 方法判断是否为查询，不改变既有写入或 `useTable` 默认行为。字段省略及写入排除规则见 [FE-006 查询条件提交边界](工程与代码生成规范.md#查询条件的空值提交边界)。

```ts
// 前提：消费者已安装并核实 queryFormat 配置声明与实现；以下为请求配置片段。
request({ url, method: 'get', params: query, queryFormat: { params: true } });
request({ url, method: 'post', data: query, queryFormat: { data: true } });
request({
  url,
  method: 'post',
  data: { ids, fields, format, filter: query },
  queryFormat: { data: { paths: [['filter']] } },
});
```

`params` 和 `data` 目标均支持 `true` 或 `{ paths?: readonly (readonly string[])[]; preserveEmptyPaths?: readonly (readonly string[])[] }`。省略 `paths` 时格式化整个目标；提供时只处理精确路径，不接受含点字符串或通配符。导出指定 `data.filter` 清理后为空则删除 `filter` 键，未选中的外层字段保持；`preserveEmptyPaths` 相对 `params/data` 根，例如 `[['filter', 'deletedAt']]`。不能把数组或 FormData 根冒充普通查询对象。格式化配置本身不进入请求头或请求体。

普通对象字段递归格式化；未输入、`null`、空串/纯空白、空数组和空普通对象字段不传，保留 `0/false`、非空原字符串和特殊对象。非空数组仅复制容器，元素引用和索引保持，不是深快照。精确空路径例外不豁免非空父对象的所有子字段；保留 `undefined` 不改变原序列化协议，契约要求 `null` 时应明确提供 `null`。

独立构造条件、不经请求层时仍可直接使用纯函数：

```ts
import { formatQueryParams } from '@fxft/aura-web-kit/utils/query';

// 生成新条件对象，不修改查询表单；不用于新增、编辑写入的清空语义。
const condition = formatQueryParams({ keyword: '', status: 0, enabled: false });
// condition 为 { status: 0, enabled: false }
```

2026-11-03 核对状态：queryFormat 与 formatQueryParams 已随 1.9.5 发布，当前验证项目已安装 1.9.6；其 `/http`、`/http/service` 的公开查询格式化类型、Axios 配置扩展和 `/utils/query` 的纯函数声明均已核对。其他项目仍按实际安装包取证，目录完整不代表全部业务查询已迁移。
公共包发布证据：2026-11-03，1.9.5，源码提交 37ecefd74d4225f55a63069894dfe00162eec558 已推送，私服读回版本与 tarball integrity 一致。规范自身仍为待提交工作树，不能以公共包提交代替规范 sourceCommit。

### 联邦、路由、国际化与启动

| 公开入口             | 主要导出或类型                                                                                              | 用途                               | 运行环境 / 绑定要求         |
| -------------------- | ----------------------------------------------------------------------------------------------------------- | ---------------------------------- | --------------------------- |
| `/i18n/runtime`      | `mergeLocaleMessages`、`flatLocaleMessages`、`createAuraI18nRuntime`                                        | 项目语言合并、初始化与销毁         | 浏览器                      |
| `/router`            | `createAuraRouterRuntime`、`createRouterApi`、`formatMenuTree`                                              | 路由初始化与菜单运行时             | 浏览器；使用项目绑定        |
| `/router/utils`      | `formatFlatteningRoutes`、`formatTwoStageRoutes`、`getFirstAccessibleMenuPath`、`dynamicImport`             | 路由树、权限过滤与动态导入         | 浏览器；使用项目绑定        |
| `/config/site`       | `createSiteConfig`                                                                                          | 站点配置工厂                       | 浏览器                      |
| `/federation/config` | `AURA_FRONTEND_SERVICE_NAME_KEY`、`defaultI18nScanDirs`、`federationExposeDefaults`、`getRemoteScopeClass`  | 联邦默认配置、scope 与身份上下文   | 浏览器；配置或 runtime 适配 |
| `/federation`        | `createFederationRemotes`、`createFederationI18n`、`createFederationStyles`、`createFederationRegistry`     | 远程注册、样式、语言和页面加载工厂 | 浏览器；配置或 runtime 适配 |
| `/federation/retry`  | `getRemoteAutoRetryDelays`、`getRemoteLoadErrorMessage`、`isTransientRemoteLoadError`、`waitForRemoteRetry` | 远程失败识别与重试间隔             | 浏览器                      |
| `/i18n`              | `auraMessages`、`normalizeAuraLocale`、`createAuraTranslator`                                               | 库内语言与翻译                     | 浏览器                      |
| `/bootstrap`         | `createAuraBootstrap`                                                                                       | 启动缓存恢复与系统配置刷新         | 浏览器；使用项目绑定        |

### 浏览器工具

| 公开入口                  | 主要导出或类型                                                                              | 用途                       | 运行环境 / 绑定要求    |
| ------------------------- | ------------------------------------------------------------------------------------------- | -------------------------- | ---------------------- |
| `/browser/config-manager` | `createConfigManager`                                                                       | 浏览器配置管理             | 浏览器                 |
| `/browser/build-info`     | `createBuildInfoReporter`                                                                   | 构建信息报告               | 浏览器                 |
| `/browser/iconfont-list`  | `createIconfontList`                                                                        | 字体图标列表               | 浏览器                 |
| `/browser/title`          | `createTitleHooks`                                                                          | 页面标题绑定               | 浏览器                 |
| `/browser/window`         | `openWindow`、`getQueryString`                                                              | 窗口与地址查询             | 浏览器                 |
| `/browser/loading`        | `NextLoading`                                                                               | 页面加载状态               | 浏览器                 |
| `/browser/anti-debug`     | `createAntiDebug`                                                                           | 反调试驱动                 | 浏览器                 |
| `/browser/app-properties` | `createAppProperties`                                                                       | 应用属性绑定               | 浏览器                 |
| `/browser/url`            | `getBrowserOrigin`、`getBrowserFullUrl`、`getBrowserApiUrl`                                 | 浏览器地址解析             | 浏览器                 |
| `/browser/watermark`      | `default`                                                                                   | 页面水印                   | 浏览器                 |
| `/browser/markdown`       | `fetchRemoteMdFile`                                                                         | 远程 Markdown 读取         | 浏览器                 |
| `/browser/iconfont`       | `getIconfontSources`、`parseIconfontSources`、`inspectIconfontCss`、`createIconfontService` | 字体源、CSS 解析与加载     | 浏览器                 |
| `/browser/assets`         | `createFederationAssets`                                                                    | 提供方资源根路径与样式 URL | 浏览器；传入提供方 URL |
| `/browser/events`         | `createEventBus`                                                                            | 实例事件总线               | 浏览器                 |
| `/browser/download`       | `saveBlobFile`、`createDownloadService`、`handleBlobFile`、`downBlobFile`                   | 文件下载与响应处理         | 浏览器                 |
| `/browser/xlsx`           | `createXlsxBlob`                                                                            | 工作簿 Blob 与列宽         | 浏览器                 |

### 纯工具与格式处理

| 公开入口                  | 主要导出或类型                                                                                                 | 用途                                                                       | 运行环境 / 绑定要求             |
| ------------------------- | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- | ------------------------------- |
| `/utils/image`            | `applyImageFallback`                                                                                           | 图片失败降级                                                               | 浏览器                          |
| `/utils/requestData`      | `normalizeJsonRequestData`                                                                                     | JSON 请求数据归一化                                                        | 浏览器                          |
| `/utils/query`            | `formatQueryParams`、`FormatQueryParamsOptions`                                                                | 纯函数构造查询条件，移除未设置字段并按精确路径保留契约空值；不用于写入 DTO | 浏览器运行时纯工具；无 DOM 依赖 |
| `/utils/framework`        | `createFrameworkUtilities`                                                                                     | 混合工具实例绑定                                                           | 浏览器                          |
| `/utils/empty-text`       | `formatEmptyText`                                                                                              | 空文本格式化                                                               | 浏览器                          |
| `/utils/phoneMask`        | `isValidContactPhone`、`maskContactPhone`                                                                      | 手机号校验与脱敏                                                           | 浏览器                          |
| `/utils/importValidation` | `getImportValidationRowValue`                                                                                  | 导入错误行读取                                                             | 浏览器                          |
| `/utils/authFunction`     | `auth`、`auths`、`authAll`                                                                                     | 权限函数                                                                   | 浏览器                          |
| `/utils/errorCode`        | `default`                                                                                                      | 错误码映射                                                                 | 浏览器                          |
| `/utils/coordinate`       | `transformCoordinate`、`toAmapCoordinate`、`fromAmapCoordinate`                                                | 坐标转换                                                                   | 浏览器                          |
| `/utils/string`           | `toUnderline`                                                                                                  | 字符串命名转换                                                             | 浏览器                          |
| `/utils/array`            | `judgmentSameArr`、`removeDuplicate`、`isObjectValueEqual`                                                     | 数组去重与对象比较                                                         | 浏览器                          |
| `/utils/tree`             | `handleTree`                                                                                                   | 树形结构转换                                                               | 浏览器                          |
| `/utils/uuid`             | `generateUUID`                                                                                                 | UUID 生成                                                                  | 浏览器                          |
| `/utils/params`           | `serializeRequestParams`                                                                                       | 请求参数序列化                                                             | 浏览器                          |
| `/utils/date`             | `dateTimeStr`、`dateStr`、`timeStr`、`formatDateStandard`                                                      | Day.js 日期格式与兼容接口                                                  | 浏览器                          |
| `/utils/validate`         | `validateNull`、`rule`、`getRegExp`                                                                            | 表单校验规则                                                               | 浏览器                          |
| `/utils/tools-validate`   | `verifyNumberPercentage`、`verifyNumberPercentageFloat`、`verifyNumberIntegerAndFloat`、`verifiyNumberInteger` | 输入校验与处理                                                             | 浏览器                          |

### 指令与 Store

| 公开入口                       | 主要导出或类型               | 用途                | 运行环境 / 绑定要求 |
| ------------------------------ | ---------------------------- | ------------------- | ------------------- |
| `/directive`                   | `directive`                  | 公共指令安装        | 浏览器              |
| `/directive/authDirective`     | `authDirective`              | 权限指令            | 浏览器              |
| `/directive/customDirective`   | `wavesDirective`             | 波纹指令            | 浏览器              |
| `/directive/focus`             | `focusDirective`             | 聚焦指令            | 浏览器              |
| `/directive/loadingScrollLock` | `loadingScrollLockDirective` | 加载态滚动锁        | 浏览器              |
| `/stores/dict`                 | `dict`                       | 字典缓存 Store      | 浏览器              |
| `/stores/param`                | `param`                      | 参数缓存 Store      | 浏览器              |
| `/stores/userInfo`             | `createUserInfoStore`        | 用户信息 Store 工厂 | 浏览器              |
| `/stores/tagsViewRoutes`       | `createTagsViewRoutesStore`  | 标签路由 Store 工厂 | 浏览器              |
| `/stores/routesList`           | `useRoutesList`              | 路由列表 Store      | 浏览器              |
| `/stores/requestOldRoutes`     | `useRequestOldRoutes`        | 历史请求路由 Store  | 浏览器              |
| `/stores/keepAliveNames`       | `useKeepALiveNames`          | 缓存组件名 Store    | 浏览器              |
| `/stores/msg`                  | `useMsg`                     | 消息 Store          | 浏览器              |

### 主题内部公共 TS

供核心主题维护和明确需要该公开能力的场景使用；布局 Vue、样式、资源和远程契约仍由 aura-core 提供，业务不据此复制主布局。

| 公开入口                                        | 主要导出或类型                                                          | 用途                | 运行环境 / 绑定要求       |
| ----------------------------------------------- | ----------------------------------------------------------------------- | ------------------- | ------------------------- |
| `/theme-core/types/layout`                      | `AsideState`、`ColumnsAsideState`、`BreadcrumbState`、`SearchState`     | 布局状态类型        | 类型 / 声明；核心按需绑定 |
| `/theme-core/utils/device`                      | `isMobileDevice`                                                        | 移动设备判断        | 浏览器；核心按需绑定      |
| `/theme-core/hooks/useHorizontalWheelScroll`    | `useHorizontalWheelScroll`                                              | 横向滚轮            | 浏览器；核心按需绑定      |
| `/theme-core/hooks/usePageZoom`                 | `PAGE_ZOOM_MIN`、`PAGE_ZOOM_MAX`、`PAGE_ZOOM_STEP`、`PAGE_ZOOM_DEFAULT` | 页面缩放与坐标换算  | 浏览器；核心按需绑定      |
| `/theme-core/hooks/useUIState`                  | `useUIState`                                                            | 布局 UI 状态        | 浏览器；核心按需绑定      |
| `/theme-core/stores/layout`                     | `useLayoutStore`                                                        | 布局 Store          | 浏览器；核心按需绑定      |
| `/theme-core/layout/navMenu/menuIconVisibility` | `shouldShowMenuIcon`                                                    | 菜单图标显隐        | 浏览器；核心按需绑定      |
| `/theme-core/constants/themeDefaults`           | `createThemeDefaults`                                                   | 主题默认值工厂      | 浏览器；核心按需绑定      |
| `/theme-core/utils/lockScreenState`             | `createLockScreenState`                                                 | 锁屏状态工厂        | 浏览器；核心按需绑定      |
| `/theme-core/utils/theme-manager`               | `createThemeManager`                                                    | 主题管理工厂        | 浏览器；核心按需绑定      |
| `/theme-core/utils/theme`                       | `createThemeColors`                                                     | 主题颜色工厂        | 浏览器；核心按需绑定      |
| `/theme-core/utils/themeCssVariables`           | `createThemeCssVariables`                                               | 主题 CSS 变量工厂   | 浏览器；核心按需绑定      |
| `/theme-core/hooks/useThemeConfigStorage`       | `createThemeConfigStorage`                                              | 主题配置存储绑定    | 浏览器；核心按需绑定      |
| `/theme-core/hooks/useFontSize`                 | `createFontSize`                                                        | 字体大小绑定        | 浏览器；核心按需绑定      |
| `/theme-core/hooks/useThemeColorPicker`         | `createThemeColorPicker`                                                | 主题选色绑定        | 浏览器；核心按需绑定      |
| `/theme-core/hooks/useThemeFilters`             | `createThemeFilters`                                                    | 主题滤镜绑定        | 浏览器；核心按需绑定      |
| `/theme-core/hooks/useFaviconManager`           | `createFaviconManager`                                                  | 站点图标绑定        | 浏览器；核心按需绑定      |
| `/theme-core/hooks/useTemplateSelection`        | `createTemplateSelection`                                               | 布局模板选择        | 浏览器；核心按需绑定      |
| `/theme-core/hooks/useTemplateManagement`       | `createTemplateManagement`                                              | 布局模板管理        | 浏览器；核心按需绑定      |
| `/theme-core/hooks/useLoginTemplateSelection`   | `createLoginTemplateSelection`                                          | 登录模板选择        | 浏览器；核心按需绑定      |
| `/theme-core/hooks/useThemeRuntime`             | `createThemeRuntime`                                                    | 主题运行时工厂      | 浏览器；核心按需绑定      |
| `/theme-core/stores/themeConfig`                | `createThemeConfigStore`                                                | 主题 Store 工厂     | 浏览器；核心按需绑定      |
| `/theme-core/stores/login`                      | `createLoginStore`                                                      | 登录界面 Store 工厂 | 浏览器；核心按需绑定      |
| `/theme-core/theme/font`                        | `createThemeFont`                                                       | 主题字体工厂        | 浏览器；核心按需绑定      |
| `/theme-core/contracts`                         | `LayoutTemplateKey`                                                     | 主题绑定契约        | 类型 / 声明；核心按需绑定 |
| `/theme-core/config-manager`                    | `createConfigManager`                                                   | 主题缓存恢复与应用  | 浏览器；核心按需绑定      |

### 类型与声明

| 公开入口             | 主要导出或类型                                                                          | 用途             | 运行环境 / 绑定要求 |
| -------------------- | --------------------------------------------------------------------------------------- | ---------------- | ------------------- |
| `/types/state`       | `UserInfosState`、`KeepAliveNamesState`、`RequestOldRoutesState`、`TagsViewRoutesState` | 公共状态类型     | 类型 / 声明         |
| `/types/axios`       | `声明扩展`                                                                              | Axios 声明扩展   | 类型 / 声明         |
| `/types/assets`      | `default`                                                                               | 静态资源声明     | 类型 / 声明         |
| `/types/remote-core` | `default`                                                                               | 精确核心远程声明 | 类型 / 声明         |
| `/types`             | `RouteItem`、`RouteToFrom`、`RouteItems`、`RefType`                                     | 公共接口与类型   | 类型 / 声明         |
| `/types/ambient`     | `声明扩展`                                                                              | 环境全局声明     | 类型 / 声明         |
| `/types/vue`         | `声明扩展`                                                                              | Vue 类型扩展     | 类型 / 声明         |

### 构建端

| 公开入口                    | 主要导出或类型                                                                                                                                                    | 用途                                     | 运行环境 / 绑定要求 |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- | ------------------- |
| `/vite/component-overrides` | `createComponentOverrideResolver`                                                                                                                                 | 本地组件编译期覆盖                       | Node 构建           |
| `/vite`                     | `generateI18nImports`、`createGitBuildInfo`、`auraAutoOptimizeDeps`、`createAuraAutoImportPreset`、`pruneFederationSsrImports`、`stabilizeFederationDevOptimizer` | 语言生成、自动导入、预构建和联邦构建插件 | Node 构建           |
| `/postcss`                  | `createAuraPostcssPlugins`                                                                                                                                        | Tailwind scope 与样式兼容插件            | Node 构建           |

## 四、构建与 UI 配套

Vite 使用 `/vite` 的 `auraAutoOptimizeDeps`，复用实际组件 resolver 工厂、`createAuraAutoImportPreset` 映射与 exposes；不再展开固定全量预构建清单。移除 `stabilizeFederationModuleScan`，保留 SSR 清理、dev 优化和远程预加载跳过插件。PostCSS 沿用 `/postcss` 的 `createAuraPostcssPlugins`。TypeScript 配套工具链、配置和冷启动取证见模块联邦规范的“工具链与自动预构建基线”。

公共 UI 不属于 web-kit；使用 aura-ui 的 `AuraUIResolver` 和 `provideAuraUiConfig`，见 《组件复用与公司基础组件库规范》。地图、视频按业务需要接入 ui-plus。

## 五、1.6.15 使用要点

- `SocialLoginEnum.ALIPAY` 已是 `/api/login` 的公共枚举项；登录协议由 `createLoginApi` 与用户 Store 使用，不在项目扩展同名枚举。
- `createAuraAutoImports` 包含 `LoginTypeEnum`、`LoginErrorEnum`、`SocialLoginEnum` 的按需运行时导入；类型由 `/types/ambient` 提供。自动导入与类型声明都需接入，不能只写全局类型而缺少运行时值。
- `/browser/loading` 的 `NextLoading.start/done` 统一遮罩生命周期，公共路由在导航结束后关闭 loading。失败远程页应在内容区呈现重试状态；不要在项目复制遮罩去重或延迟关闭补丁。
- 联邦失败路径验收包含首次进入不可用远程页面时遮罩能结束，宿主与远程包副本不会相互误关新一轮 loading。
## 六、维护与核对

1. 从目标项目的 package.json、锁文件和已安装 `@fxft/aura-web-kit/package.json` 确认版本。
2. 对比 `exports` 与本表子入口；逐项核对 `.d.ts`、导出类型、运行环境和工厂所需依赖。不要直接把源码文件列表当公共 API。
3. 更新版本说明、场景映射和受影响示例；公开名称变化须验证使用处。新增清单项不能自动授权项目升级依赖。
4. 正式源维护于 nexus 的 `docs/PIGX前端开发规范`；同步两个技能引用的快照，并运行技能校验。技能入口只维护选用原则与导航，不重复罗列全部能力。
