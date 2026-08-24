# 命名规范

正式规则以 `../knowledge/PIGX前端开发规范/工程与代码生成规范.md`、对应页面模式和当前业务域现有代码为准。

## 决策顺序

```text
当前业务域约定 → 最新版正式规范 → 业务域 → 业务对象 → 功能动作 → 技术类型
```

## 文件和目录

- Vue 文件使用 kebab-case，路由页面入口通常为 `index.vue`。
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
