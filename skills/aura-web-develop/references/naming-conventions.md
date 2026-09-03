# 命名规范

正式规则以 `../knowledge/PIGX前端开发规范/工程与代码生成规范.md`、对应页面模式和当前业务域现有代码为准。

## 决策顺序

```text
当前业务域约定 → 最新版正式规范 → 业务域 → 业务对象 → 功能动作 → 技术类型
```

## 文件和目录

- 项目、目录、Vue/CSS/SCSS/HTML 和静态资源文件使用小写 `kebab-case`，例如 `device-location-picker.vue`；JavaScript/TypeScript 模块文件使用 `camelCase`，例如 `mapConfig.ts`、`coordinateTransform.ts`。
- 组合式 Hook 文件使用 `useXxx.ts`，例如 `useDeviceQuery.ts`；Hook 导出函数使用 `useDeviceQuery`。
- Vue 组件在模板和组件名中使用 PascalCase；文件名遵循本项目统一的 `kebab-case` 文件规则。
- 不因为目录历史写法批量重命名已有文件；新增文件按以上规则命名，修改已有文件时保持当前模块的一致性。

## 代码标识符

- 函数、方法、变量、参数和对象成员使用 lowerCamelCase，名称必须表达业务动作或业务含义。
- 常量使用 UPPER_SNAKE_CASE，单词之间使用下划线，避免无语义缩写。
- 类型、接口、枚举和类使用 PascalCase；布尔值使用 `is`、`has`、`can`、`should` 等语义前缀。
- API 方法使用“动作 + 业务对象”，例如 `getDeviceList`、`updateDeviceStatus`；禁止使用 `query`、`save`、`data1` 等过泛名称。

## CSS 与 HTML

- CSS/SCSS 类名使用小写 `kebab-case`；组件样式优先采用 BEM：`block__element--modifier`。
- 选择器避免直接使用标签名、ID 和全局通配符，优先使用业务类名；嵌套层级保持简洁。
- CSS 属性按项目格式化工具输出，每个选择器和属性独占一行；长度为 0 时省略单位。
- Vue Template 使用语义化标签、双引号属性和简洁表达式；复杂表达式提取为计算属性或方法。
- 页面放在 `src/views/<业务域>/<业务模块>/`，私有组件放在同目录 `components/`。
- API 放在 `src/api/<业务域>/`，目录结构先遵循相邻模块。
- 业务 Composable 放在页面目录 `composables/`；跨业务稳定后再提升到 `src/hooks/`。
- 不使用 `common`、`temp`、`new`、`test`、`Page.vue`、`useData` 等缺少业务语义的正式命名。

## API 函数

最新版工程规范使用 `get/list/create/update/delete + 业务对象` 的语义命名，部分正式页面模式使用 `fetchList/getObj/addObj/putObj/delObj`。因此：

1. 优先跟随当前业务域相邻 API 的一致命名。
2. 新业务域按最新版工程规范使用动词 + 业务对象。
3. 复用正式页面模式时可沿用该模式已验证的函数名。
4. 不为了统一风格批量重命名已有公开 API。
5. 业务特殊操作使用明确动词，如 `syncOrder`、`exportOrders`、`changeOrderStatus`。

禁止把旧版“五段式”作为全项目强制规则。

## 组件和 Composable

- 页面私有组件文件使用 kebab-case，组件名使用 PascalCase。
- Props、Emits、Exposes 使用具体业务动作命名。
- Composable 使用 `use<业务对象><能力>`，例如 `useOrderQuery`。
- Store ID、文件名和状态范围体现业务域，不使用 `myStore`。

## 路由和模块联邦

- 菜单、路由、Expose、`remoteName`、`remoteEntryName` 和 `systemId` 按最新版路由与模块联邦规范命名。
- 新项目必须替换 `pigx-nexus`、`pigxNexus` 占位名。
- 部署环境内身份不可重复，不混用 remoteName、部署路径和系统 ID。

## i18n

- 页面业务语言包放在当前业务目录 `i18n/zh-cn.ts`、`i18n/en.ts`。
- 公共操作优先复用 `common.*`。
- 业务 key 使用稳定的业务域和含义命名，不把中文文案直接作为 key。
