# aura-ui 能力清单与接入规范

## 一、能力与选用原则

本文汇总 `@fxft/aura-ui` 当前公开能力，包含 **39 个组件和 49 条 package exports 规则**。组件说明依据本地 SDK 的公开声明、实现和组件 API 文档整理。接入时核对项目实际安装包的公开导出和契约。

- 公共 UI 优先查询本清单，再读取实际组件的 Props、Events、Slots 和公开实例方法；需要公共 TS、Hook、请求和模块联邦运行时能力时查询 aura-web-kit 清单。
- 使用 `Aura` 前缀组件名；源码仓库名 `aura-web-sdk` 不是 npm 包名，不虚构 `@fxft/aura-web-sdk`，也不虚构 `AuraButton`、`AuraTag`、`AuraDatePicker`。
- 页面只绑定项目服务、资源和业务数据；通用组件改进进入 aura-ui，通用 TS 能力进入 web-kit，不在页面复制库内实现。
- 地图、直播、录像回放、PTZ 和多路视频按专项规范使用 `@fxft/ui-plus`；`AuraVideoPlayer` 用于视频文件播放，不承诺这些监控能力。
- 以下为浏览器 Vue 3 + Vite 接入。完整参数和 ref 方法以目标版本声明、运行实现为准；声明存在但未实现的行为不能作为可用能力。

### 依赖与安装前提

| 依赖 | 包声明或接入要求 | 项目处理 |
| --- | --- | --- |
| Vue | peer：`^3.5.13` | 复用项目 Vue 实例；模块联邦沿用框架 singleton 配置 |
| `@fxft/aura-web-kit` | peer：`^1.0.0` | 固定为项目已验证版本，另核对实际使用的公开子入口；PIGX 按 web-kit 能力清单核对已验证基线 |
| Element Plus | 包内依赖：`^2.13.1` | 与项目版本统一；PIGX 沿用 `2.14.6` 基线 |
| `unplugin-vue-components` | Resolver 方案需要的开发依赖 | 已有插件合并配置；全量或手动引入无需为 Aura 另装插件 |
| vue-i18n | 多语言应用按需提供 | 复用现有实例，SDK 不创建 i18n 实例 |

选定组件后先核对项目依赖声明、锁文件和实际安装包，满足需求时直接复用。缺失或不满足需求时按 [下载与安装说明](公司组件库下载说明/README.md) 检查目标包并按授权安装，随后继续下文的组件导入、样式及服务绑定。

包已使用的 web-kit 入口包括 `api/common`、`hooks/permissions`、`browser/iconfont-list`、`utils/tools-validate` 等；满足 peer 版本范围后仍需核对实际导出。私服配置沿用项目下载规范，凭据不写入业务源码或技能文档。

## 二、公开入口与导入边界

| 入口 | 主要导出或用途 | 运行环境与边界 |
| --- | --- | --- |
| `@fxft/aura-ui` | 默认导出安装函数；命名导出 39 个 Aura 组件、配置 API、`LinkTypeEnum` 及部分公共类型 | 浏览器 ESM；全量注册会引入全部组件，普通页面优先公开子入口或 Resolver |
| `@fxft/aura-ui/<组件子入口>` | 对应组件 default 导出；部分入口另导出该组件类型或枚举 | 浏览器 ESM；39 个子入口见下表 |
| `@fxft/aura-ui/config` | `AURA_UI_CONFIG_KEY`、`mergeAuraUiConfig`、`useAuraUiConfig`、`provideAuraUiConfig`、`installAuraUiConfig`；类型 `AuraUiConfig` | Vue 应用上下文；组件按需引入时无需安装整套组件即可配置 |
| `@fxft/aura-ui/resolver` | `AuraUIResolver` 命名及 default 导出；Resolver 选项与结果类型 | Node 构建；支持 ESM/CJS，不能作为浏览器服务调用 |
| `@fxft/aura-ui/locale/zh-cn`、`@fxft/aura-ui/locale/en` | 默认导出语言消息对象 | 并入应用已有 i18n 实例，不创建第二套实例 |
| `@fxft/aura-ui/style.css` | 统一样式 | 按应用样式方案加载一次；与按需样式方案二选一 |
| `@fxft/aura-ui/dist/index.css`、`@fxft/aura-ui/dist/theme-chalk/index.css` | 已有导出样式入口 | 现有项目可保留其中一种，不再叠加统一样式 |
| `@fxft/aura-ui/dist/theme-chalk/*` | `var.css`、`base.css`、各组件 CSS 等公开样式路径 | 按需样式；不要推断未检查的文件一定存在 |
| `@fxft/aura-ui/dist/es/components/*` | package exports 中保留的组件产物通配路径 | 新接入优先语义化组件子入口，不据此依赖内部子组件或私有文件 |

49 条规则包含：根入口 1 条、组件入口 39 条、配置/Resolver/语言入口 4 条、样式及产物通配规则 5 条。通配规则不按匹配到的文件数展开，也不计为新增组件。

### 引入方式选择

| 方式 | 注册范围 | 适用场景 |
| --- | --- | --- |
| 全量引入 | 应用全局注册全部 39 个组件 | 希望统一注册整套组件的独立应用 |
| Resolver 自动按需 | 编译模板时导入实际使用的组件 | 普通业务页面及模块联邦提供方 |
| 手动按需 | 显式导入组件，在当前组件或应用中使用 | 少量组件、脚本组件对象或需要控制导入的位置 |

### 全量引入

在应用入口导入默认安装函数、加载统一样式，并在挂载前注册：

```ts
import { createApp } from 'vue';
import AuraUI from '@fxft/aura-ui';
import App from './App.vue';

import 'element-plus/dist/index.css';
import '@fxft/aura-ui/style.css';

const app = createApp(App);

app.use(AuraUI);
app.mount('#app');
```

已有应用将注册和样式导入合并到现有入口，不重复创建应用。注册后，后代模板可直接使用全部 Aura 前缀组件，无需再为这些组件配置 AuraUIResolver；其他组件的 Resolver 沿用项目配置。全量引入会带入整套组件依赖，样式也需按上例加载。

需要请求等应用能力时，将上面的 `app.use(AuraUI)` 替换为以下注册方式。示例 request 使用 PIGX 项目已有绑定，其余配置按第五节中实际使用的组件补充：

```ts
import request from '/@/config/aura/request';

app.use(AuraUI, { request });
```

第二个参数由安装函数传给 `installAuraUiConfig`，在同一次注册中完成配置注入，无需再单独调用该函数。语言包按第六节并入现有 i18n。全量注册作用于当前 Vue 应用；模块联邦 expose 页面仍须按第五节在实际组件树边界绑定服务，不能依赖提供方入口已执行。

### 按需解析

向项目现有 `Components` 配置追加 Resolver，不覆盖其他 Resolver：

```ts
import Components from 'unplugin-vue-components/vite';
import AuraUIResolver from '@fxft/aura-ui/resolver';

Components({
  dirs: [],
  dts: './components.d.ts',
  resolvers: [AuraUIResolver()],
});
```

Resolver 将组件解析为 `@fxft/aura-ui/<子入口>` 的 default 导入，默认同时添加 `var.css`、`base.css` 和对应组件 CSS。

| Resolver 选项 | 契约 |
| --- | --- |
| `importStyle` | `'css'`（默认）或 `false`；false 仅关闭组件 CSS |
| `injectGlobal` | 默认 true；false 关闭全局 CSS 注入 |
| `globalStyle` | 自定义全局样式数组，默认 `var.css`、`base.css` |
| `functionMap` | 显式函数导入映射；不会自动产生组件库没有的服务 API |

模板支持 PascalCase 与 kebab-case 标签。脚本中的组件对象、`h(Component)`、类型和枚举需显式导入；后台 JSON 动态组件名需由消费应用注册。`components.d.ts` 仅提供类型提示，不证明运行时完成解析、注册或样式加载。

### 显式导入与样式

```ts
import AuraDictTag from '@fxft/aura-ui/dict-tag';
import type { AuraDictOption } from '@fxft/aura-ui';
import { LinkTypeEnum } from '@fxft/aura-ui/link-picker';

import '@fxft/aura-ui/dist/theme-chalk/var.css';
import '@fxft/aura-ui/dist/theme-chalk/base.css';
import '@fxft/aura-ui/dist/theme-chalk/dict-tag.css';
```

上述样式应放在项目统一样式边界，不在每个页面重复维护。组件 JS 不自动加载 CSS。三种方案按项目现状选用：

| 方案 | 配置 |
| --- | --- |
| Resolver 按需样式 | `AuraUIResolver()`；自动注入实际使用组件及其基础样式 |
| 统一样式 | 应用统一加载 `element-plus/dist/index.css` 和 `@fxft/aura-ui/style.css`；Resolver 使用 `{ importStyle: false, injectGlobal: false }` |
| 手动按需样式 | 加载 `var.css`、`base.css` 及所用组件 CSS；补齐应用额外使用的 Element Plus 组件样式 |

主题和业务覆盖样式放在基础样式之后。库内浏览器编辑器、播放器等依赖不能默认用于 SSR；SSR 场景在客户端动态导入相应组件，单纯添加 `ClientOnly` 不会阻止顶层 import 在服务端执行。

手动按需时，在 `<script setup>` 中导入的组件可直接用于当前模板；以下例子中的选项由调用方加载：

```vue
<script setup lang="ts">
import AuraDictTag from '@fxft/aura-ui/dict-tag';
import type { AuraDictOption, AuraDictValue } from '@fxft/aura-ui';

defineProps<{
  value: AuraDictValue;
  options: AuraDictOption[];
}>();
</script>

<template>
  <AuraDictTag :value="value" :options="options" />
</template>
```

样式按前面的统一或手动按需方案加载。普通 `<script>` 组件需在自身 components 中注册；应用级注册使用 `app.component('AuraDictTag', AuraDictTag)`。动态 JSON 组件名由实际消费该规则的应用注册，不能仅生成类型声明。

## 三、39 个公开组件能力清单

下表子入口统一省略 `@fxft/aura-ui/`。API 文件路径相对 `aura-web-sdk` 仓库；消费项目先核对实际安装包中该入口对应的 `.d.ts` 和运行产物。表中只列影响选型的主要契约，不代替完整 API。

### 展示与基础交互（8 个）

| 组件 / 子入口 | 主要能力与输入输出 | 接入边界 | API 文件 |
| --- | --- | --- | --- |
| `AuraTip` / `tip` | `content`、`placement`、`effect`；default/content 插槽 | content 插槽优先于同名属性 | `docs/component/tip.md` |
| `AuraDelWrap` / `del-wrap` | default 插槽、`showClose`；close 事件、`handleClose()` | 只通知关闭，删除数据由业务处理，不自带删除确认请求 | `docs/component/del-wrap.md` |
| `AuraTagList` / `tag-list` | `v-model: string[]`；新增、移除标签 | `closable`、`disableAdd` 可读 UI 默认值；新增不自动去重 | `docs/component/tag-list.md` |
| `AuraNameAvatar` / `name-avatar` | `name`、`faceUrl`、`num`、颜色和缩放 | 姓名、图片或计数头像，无业务请求 | `docs/component/name-avatar.md` |
| `AuraShortcutCard` / `shortcut-card` | `icon`、`label`、`color`；click 事件 | 图标可用 UI 默认值；导航由业务处理 | `docs/component/shortcut-card.md` |
| `AuraNoticeBar` / `notice-bar` | 滚动文字、模式、左右图标；close/link 事件及插槽 | 无通知查询或消息推送服务 | `docs/component/notice-bar.md` |
| `AuraSvgIcon` / `svg-icon` | `name`、优先 `src`、尺寸、颜色和地址前缀 | Element Plus 图标、本地 symbol、图片、字体类；本地图标与字体资源由项目提供 | `docs/component/svg-icon.md` |
| `AuraImagePreview` / `image-preview` | ElImage 属性、`fit`、`preview`；error 插槽 | `getFileUrl` 可转换地址；开启单图预览，不承诺转发全部 ElImage 插槽 | `docs/component/image-preview.md` |

### 表单与弹层（8 个）

| 组件 / 子入口 | 主要能力与输入输出 | 接入边界 | API 文件 |
| --- | --- | --- | --- |
| `AuraPopup` / `popup` | `title`、`content`、`async`；open/confirm/cancel/close 事件；`open()`、`close()`、`handleEvent()` | 用 ref 打开，不虚构 modelValue；async 确认后由调用方关闭 | `docs/component/popup.md` |
| `AuraPopoverInput` / `popover-input` | 文本/选项输入；confirm、update:modelValue 事件 | 不读取 modelValue 回显；打开清空等过程也可能发模型事件，`limit` 当前不生效 | `docs/component/popover-input.md` |
| `AuraColorPicker` / `color-picker` | `v-model` 颜色、`defaultColor` 重置 | 清空可输出 null/undefined，不能限定为始终有字符串 | `docs/component/color-picker.md` |
| `AuraTreeSelect` / `tree-select` | `v-model:value` 单值、`options`、`objMap` | 非默认 v-model；清空允许 null/undefined，不承诺多选 | `docs/component/tree-select.md` |
| `AuraSign` / `sign` | `v-model` PNG data URL；`reset()`、`generate(): Promise<string>` | ref 方法不更新模型；未绘制时 generate reject，isCrop 当前不实现裁剪 | `docs/component/sign.md` |
| `AuraCrontab` / `crontab` | Quartz 风格表达式、快捷项；update:modelValue；open/set/submit 等方法 | 手工输入不发模型更新，不能当作完整 Cron 语法验证器 | `docs/component/crontab.md` |
| `AuraStrengthMeter` / `strength-meter` | `v-model:value`；change、score 事件 | 评分只作提示；disabled 只停止评分，showInput 当前不隐藏输入框 | `docs/component/strength-meter.md` |
| `AuraFormTable` / `form-table` | `v-model` 行数组、`addTemplate`、拖拽；delete 事件、增删行方法；列插槽 | `deleteRow` 不发 delete；行模型不等于业务保存接口，校验由业务表单负责 | `docs/component/form-table.md` |

### 字典、查询与组织（9 个）

| 组件 / 子入口 | 主要能力与输入输出 | 接入边界 | API 文件 |
| --- | --- | --- | --- |
| `AuraDictTag` / `dict-tag` | `options` + 单值/数组 `value`；字段键、颜色、图标、`emptyText` | 按 String 匹配；不自动请求；空值与无匹配行为不同 | `docs/component/dict-tag.md` |
| `AuraDictText` / `dict-text` | `options` + 单个 `value`；`fallback`、文字样式、截断 | 固定 label/value；不支持数组值或自定义键，不自动请求 | `docs/component/dict-text.md` |
| `AuraDictSelect` / `dict-select` | `v-model` 单值/多值；options 或 dictType/request；change | 保留 string/number 类型；自定义 request 优先于 UI request；无公开加载方法 | `docs/component/dict-select.md` |
| `AuraPagination` / `pagination` | `current`、数字 `size`、`total`；sizeChange/currentChange 事件 | 业务维护分页状态与重新查询，不虚构 update:current/update:size 双向模型 | `docs/component/pagination.md` |
| `AuraRightToolbar` / `right-toolbar` | `v-model:showSearch`；queryTable/exportExcel；附加按钮插槽 | export 为权限字符串时读 kit 权限上下文，true 时始终显示 | `docs/component/right-toolbar.md` |
| `AuraQueryTree` / `query-tree` | 必传 `query(keyword?)` 返回 `{ data: 节点数组 }`；nodeClick、default 插槽、`getdeptTree()` | 自带搜索查询；search 当前不触发，getdeptTree 不返回请求 Promise；节点 key 固定 id | `docs/component/query-tree.md` |
| `AuraChinaArea` / `china-area` | 编码路径字符串模型；options 或远程地区查询；change | 不绑定数组模型；无 options 时需 UI request，maxLevel 仅 options 模式生效 | `docs/component/china-area.md` |
| `AuraOrgTreeView` / `org-tree-view` | 必传 api、formComponent；getOrgData/handleExpand/filter；node-click、refresh | 组织管理而非单纯选择；需租户上下文及业务表单，config.menus 当前未使用 | `docs/component/org-tree-view.md` |
| `AuraOrgSelector` / `org-selector` | 用户/部门/角色/组织选择；模型和 orgList 均为 `OrgItem[]` | apiConfig 或 UI request；单选仍输出数组，禁选本人需当前用户 ID | `docs/component/orgSelector.md` |

### 上传与导入（5 个）

| 组件 / 子入口 | 主要能力与输入输出 | 接入边界 | API 文件 |
| --- | --- | --- | --- |
| `AuraUpload` / `upload` | 通用附件、回显、下载；模型/change、`submit()` | autoUpload=false 时手动提交；需 upload 配置，输出为地址字符串 | `docs/component/upload.md` |
| `AuraUploadExcel` / `upload-excel` | 导入弹窗、模板下载、错误行；`show()`、change/refreshDataList | 必须配置业务 url；change 是传输成功回调，不能直接认定业务成功 | `docs/component/upload-excel.md` |
| `AuraUploadImg` / `upload-img` | 单图 v-model 或 imageUrl；change、`clear()`；自定义 httpRequest | 自定义请求优先；原生上传与项目 request 两种路径认证不同 | `docs/component/upload-img.md` |
| `AuraUploadImgPlus` / `upload-img-plus` | 多图回显、上传、排序；模型更新；自定义上传回调 | 接收字符串/数组等，更新输出逗号 URL 字符串；需按路径配置认证 | `docs/component/upload-img-plus.md` |
| `AuraImagePaste` / `image-paste` | 点击、拖拽、可见区域全局粘贴；模型更新 | 粘贴依赖 upload.postFile；点击与粘贴成功响应解包层级不同 | `docs/component/image-paste.md` |

### 编辑、内容与选择（9 个）

| 组件 / 子入口 | 主要能力与输入输出 | 接入边界 | API 文件 |
| --- | --- | --- | --- |
| `AuraCodeEditor` / `code-editor` | 代码/JSON 编辑、v-model、mode/theme/readOnly、change；公开编辑器成员与方法 | 基于 CodeMirror 5，语言支持以已打包模式为准，不按 CodeMirror 6 API 调用 | `docs/component/code-editor.md` |
| `AuraEditor` / `editor` | HTML 富文本；`v-model:getHtml`、`v-model:getText`；自定义上传 | getText 为输出，HTML 通过 getHtml 回填，上传优先使用回调或项目 request | `docs/component/editor.md` |
| `AuraMdRenderer` / `md-renderer` | `source`、暗色主题、代码行号与复制；rendered/error | 初始化成功不表示远程资源已加载；inner_suffix 当前不生效 | `docs/component/md-renderer.md` |
| `AuraVideoPlayer` / `video-player` | 视频文件 src、poster；`play()`、`pause()` | 浏览器播放器，挂载初始化后调用；play 不返回媒体播放 Promise | `docs/component/video-player.md` |
| `AuraSafeSandboxIframe` / `safe-sandbox-iframe` | `html`、`baseUrl`、高度和顶部裁切 | 静态 HTML 的 A4 顶部预览，不作为任意业务应用嵌入容器 | `docs/component/safe-sandbox-iframe.md` |
| `AuraMindMap` / `mind-map` | 必传 `text`，将 Markdown 层级转为导图 | 浏览器渲染，不提供节点编辑或业务保存协议 | `docs/component/mind-map.md` |
| `AuraLinkPicker` / `link-picker` | 页面或外链；Link 对象模型、pages/textConfig | 确认时写回；编辑/取消不提交；提交对象完整性仍由业务校验 | `docs/component/link.md` |
| `AuraIconSelector` / `icon-selector` | 图标名称模型、iconSource/textConfig；get/clear 事件 | 字体、Element Plus、本地 symbol 来源由项目配置；搜索不写回模型 | `docs/component/icon-selector.md` |
| `AuraBusinessIconPicker` / `business-icon-picker` | 分组图片图标；valueField；模型、iconUrl、change | 依赖 UI request 和后台 sys-icon 接口；selectedIcon 需与模型一致 | `docs/component/business-icon-picker.md` |

## 四、类型与实例方法

| 需求 | 公开类型入口与边界 |
| --- | --- |
| 字典选项、值和加载函数 | 根入口的 `AuraDictOption`、`AuraDictValue`、`AuraDictRequest`；扩展字段不代表所有字典组件都会读取 |
| 业务图片图标 | 根或 `business-icon-picker` 的 `SysIconInfo` |
| 链接类型及运行枚举 | 根或 `link-picker` 的 `Link`、`LinkTypeEnum`；后者是运行时值，不能只提供全局类型 |
| 组织选择 | 根或 `org-selector` 的 `OrgItem`、`OrgSelectorApiConfig`、`OrgSelectorTextConfig` |
| 组织树 | `org-tree-view` 的类型再导出，包括 `OrgTreeViewAPI`、`OrgTreeViewConfig`；不要假定根入口导出全部组件私有类型 |
| UI 服务配置 | 根或 `config` 的 `AuraUiConfig`；索引签名允许扩展，但字段是否生效仍需核对组件实现 |

组件实例可使用 `InstanceType<typeof Component>` 配合 Vue ref 标注，调用范围按项目安装包的公开实例契约核对。主要交互方法包括 Popup 的 open/close、Upload 的 submit、UploadExcel 的 show、UploadImg 的 clear、Sign 的 reset/generate、QueryTree 的 getdeptTree、OrgTreeView 的 getOrgData/handleExpand/filter。不要通过 `$refs` 深入内部子组件，也不要把声明中的状态成员当作稳定业务接口。

## 五、应用服务绑定

### PIGX 项目与远程业务边界

在布局或远程业务入口的 setup 中绑定当前项目服务。以下示例只展示请求和消息；按实际使用的组件补充上传、租户和资源配置：

```ts
import { provideAuraUiConfig } from '@fxft/aura-ui/config';
import request from '/@/config/aura/request';
import { useMessage, useMessageBox } from '/@/config/aura/index';

const message = useMessage();
const messageBox = useMessageBox();

provideAuraUiConfig({
  request,
  message,
  confirm: (text: string) => messageBox.confirm(text),
});
```

配置通过 `Symbol.for('@fxft/aura-ui/config')` 标识的 Vue 上下文传递，仅影响后代组件。绑定所在组件自身若要消费配置，使用返回值；不要假定同一组件再次 inject 能读到自己刚 provide 的值。

独立应用可在挂载前调用 `installAuraUiConfig(app, config)`；全量注册可用 `app.use(AuraUI, config)`。远程页面不能依赖提供方 `main.ts` 必然执行，也不能把模块级可变配置作为跨应用默认值。宿主与远程页面需处于可传递 Vue 注入上下文的组件树；独立 Vue 应用需分别绑定。

`mergeAuraUiConfig` 保留未覆盖字段；仅 upload、linkPicker、iconSelector、orgSelector、orgTreeView、mdRenderer、svgIcon、dictTag、tagList、shortcutCard、formTable 分组进行一层字段合并，函数、组件和数组保留引用，不是任意深度合并。

| 配置项 | 消费场景与接入要求 |
| --- | --- |
| `request(config)` | DictSelect、ChinaArea、OrgSelector、BusinessIconPicker 等使用项目请求；各响应结构按组件契约适配，不新建业务 Axios 实例 |
| `getFileUrl(url)` | 图片预览、单图上传回显和业务图标地址解析；与项目静态/公共资源规则一致 |
| `message`、`confirm` | 消息与确认；confirm 返回 Promise，resolve 为同意，reject 为取消 |
| `upload.baseUrl`、`upload.getHeaders()` | 上传基础地址及发送时读取的认证头；回调读取当前 token/租户，不能固定启动时快照 |
| `upload.adaptationUrl/getQueryString/downBlobFile` | 上传地址、文件名及下载适配，字段按使用组件核对 |
| `upload.postFile(url, formData, headers)` | ImagePaste 粘贴上传，外层返回 `{ data: 业务响应 }`；不能直接复用不同解包层级的函数 |
| `orgTreeView.getCurrentTenant()` | 读取响应式会话，返回 `{ id, name?, userId? }` 或未就绪时 undefined |
| `orgTreeView.getTenant(tenantId)`、`isDark()` | 根租户名称补查和组织树主题；页面 api.getTenant 可优先提供名称 |
| `orgSelector.getCurrentUserId()` | 禁选当前用户；ID 类型须与接口一致 |
| `iconComponent`、`svgIcon` | 图标渲染组件、本地 symbol 前缀和图片样式；不自动生成项目图标资源 |
| `linkPicker`、`iconSelector` | 页面清单、图标异步来源与文案；组件显式配置优先的范围见对应 API |
| `mdRenderer.isDark()` | 默认 Markdown 主题，组件 isDark 属性优先 |
| `dictTag/tagList/shortcutCard/formTable` | 标签类型、标签增删、默认图标及表格删除策略等已实现默认值，不据索引签名推测更多配置 |

配置类型中的 upload 等分组较宽，接入时同时核对项目安装包的声明和组件实现。

### 上传认证与响应

原生 ElUpload 不经过项目 request 拦截器。Upload、UploadExcel、UploadImgPlus、ImagePaste 在实际发送时读取 getHeaders；显式 headers 整体替换该结果，不是合并补充。

UploadImg 优先使用显式 httpRequest。无显式 action 且存在 UI request 时走项目请求，显式 action 或缺少 UI request 时走原生上传，该路径按项目配置认证头或自定义请求。

Editor 优先使用 uploadRequest 回调，布局提供 request 时通过该服务发送 multipart，并在发送时读取当前 upload.getHeaders。文件地址优先通过 getFileUrl 处理。仅提供 upload 配置时走原生上传，认证头按编辑器初始化值生效。图片和视频共用该上传配置。

各组件的 baseUrl/baseURL 属性大小写、地址拼接、文件大小单位、成功码和响应解包方式分别核对 API。change、传输成功和业务保存成功是不同阶段；UploadExcel 的 change 不能直接用作业务成功标志。

### 组织树与业务表单

OrgTreeView 必须绑定 `api.treeData(params?)` 和 `api.delete(id)`，并传入暴露 `openDialog` 的业务表单组件。新增调用 `openDialog('add', undefined, stripLineId, parentId)`，编辑调用 `openDialog('edit', id)`；表单 refresh 触发重新查询。组件不判断删除响应的业务 code，失败需由 API 以 reject 表达。

getCurrentTenant 应读取响应式状态：会话未就绪返回 undefined；租户或用户变化重新加载，名称补查失败不阻断树加载。config.menus 不生效，字段映射不覆盖所有内部固定字段，拖拽不自带保存接口，不把它作为完全通用的组织业务协议。

### 字典与权限

Tag/Text 只消费 options；Select 使用项目选项或公开远程加载能力，不为展示组件假设自动请求。Tag 支持多值，Text 仅单值，Select 使用 modelValue 并保留编码类型；三者的空值、fallback/emptyText 和自定义字段能力不同。

PIGX 业务枚举/字典展示使用 AuraDictTag/AuraDictText，筛选或表单按需求使用 AuraDictSelect 或项目字典选项。不手写展示映射，不为普通组件默认行为额外增加未要求的业务兜底。

RightToolbar 的 export 为字符串时读取 `@fxft/aura-web-kit/hooks/permissions` 的已有权限上下文；缺失、未就绪或无权限时隐藏。export=true 始终显示；UI config 不能替代权限上下文，也不替代接口鉴权。

## 六、语言、资源与模块联邦

### 语言包接入

SDK 的 `locale/zh-cn`、`locale/en` 消息并入应用已有 i18n：先库默认文案，再应用覆盖。下面的 i18n、appZhCn、appEn 来自项目现有配置，在应用挂载前执行：

```ts
import auraUiZhCn from '@fxft/aura-ui/locale/zh-cn';
import auraUiEn from '@fxft/aura-ui/locale/en';

i18n.global.mergeLocaleMessage('zh-cn', auraUiZhCn);
i18n.global.mergeLocaleMessage('en', auraUiEn);
i18n.global.mergeLocaleMessage('zh-cn', appZhCn);
i18n.global.mergeLocaleMessage('en', appEn);
```

语言标识与项目保持一致，例如项目使用 zh-CN 时同步调整合并键。组件复用应用 `$t`，Element Plus locale 通过项目已有注册或 ElConfigProvider 同步设置；并非所有默认文字都已国际化，必要时按组件 textConfig 或显式属性传入项目翻译文案。

### 资源与远程运行

- PIGX 的请求、消息、权限、资源和表单生命周期沿用项目规则；aura-ui 不替代 `useForm`、项目 i18n 或模块联邦资源解析。源码 import 资源与 public 资源分别使用项目已有资源绑定。
- 提供方在编译期解析自己的 Aura 组件及样式，不要求宿主替其完成依赖解析；独立启动和远程加载都验证 JS 与 CSS。只在 `main.ts` 全局注册组件不能保证 expose 页面可用。
- Vue、Element Plus 等 shared 按框架已批准配置保持 singleton；不因使用 aura-ui 自行扩展 shared。库依赖中较宽的 semver 范围不替代项目精确基线。
- 模块联邦任务另按专项规范验证组件树上下文、teleport 弹层样式、资源地址与跨应用服务隔离，不在业务页面复制框架运行时修复。

## 七、接入核对

1. 从目标项目依赖声明、锁文件、实际安装包确认版本；禁止只看源码仓库版本或本地 tgz 名称判断已安装、已发布。
2. 交叉核对 package exports、根运行导出、根声明、39 个组件子入口和 Resolver 名单；不存在的名字不写入清单，内部组件不单独计数。
3. 核对实际使用组件的声明、运行实现、CSS、依赖服务和响应结构。模型名、事件载荷与实例返回值分别核对，尤其不能把声明中的兼容字段当成已实现功能。
4. 升级后重新验证 Resolver 结果、JS/CSS 文件存在、字典匹配/空值、上传认证/响应、组织租户切换和远程入口上下文；不把文件存在或静态检查通过描述为浏览器行为验收。

### 资料依据

组件资料来自本地 SDK 的 `docs/component/`、`packages/ui/index.d.ts`、组件公开声明、配置和 Resolver。接口、事件、样式及运行行为结合项目实际安装包核对。
