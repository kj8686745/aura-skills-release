# i18n 分层与去重

- 按复用范围放置文案：全项目通用文案使用 `src/i18n/`；同一业务域内两个及以上页面/模块共用的文案使用 `src/views/<业务域>/i18n/`；仅单个页面或私有组件使用的文案才放入其业务目录 `i18n/`。
- 新增 key 前必须依次搜索全局、业务域和当前模块语言包；已存在且语义一致的 key 直接复用，禁止在相邻业务模块重复定义同义文案。发现同类文案已在多个模块出现或预期跨模块复用时，应按复用范围主动提取到全局或业务域公共语言包，并同步替换本次涉及模块的重复 key。
- 业务域共享 key 使用业务域命名空间，例如 `iot.clearFilter`；不得以页面名称承载跨页面通用语义。中英文语言包必须同步维护。
- 不为整理目录而无差别迁移历史 key；仅在本次需求涉及的模块中合并已确认重复、且不影响远程暴露和现有调用契约的文案。

## 枚举、字典、国际化与占位硬约束

- 编码前解析 API/OpenAPI、TypeScript 类型和相邻业务契约中的枚举与 `dictKey`，逐字段列出“筛选、表格、详情、表单”的渲染方式。接口类型中带字典的字段必须保留 `/** @dictKey <key> */` 注释，作为可扫描契约。
- 有字典的筛选与表单必须使用 `DictSelect` 或项目字典选项；表格状态使用 `DictTag`，详情只读展示使用 `DictText`。禁止硬编码枚举选项，禁止直接输出对应 `*Name` 快照；无字典的真实名称字段除外。
- 业务 `.vue/.ts` 中用户可见文案一律使用 `t()` / `$t()`，覆盖 label、title、placeholder、按钮、列名、卡片标题与说明、Dialog/Drawer、空态、校验与消息。注释、接口/字典返回值、后端异常、mock 数据和 i18n 文件除外。
- 新文案先复用 `common`；跨两个及以上业务模块、但不属于全局 common 的文案上提到业务域公共 `i18n/`；中英文 key 同步存在。不得在页面 i18n 重复定义已有 common 或业务域文案。
- 每个可编辑或筛选的 `el-input`、`el-select`、`el-date-picker`、`el-input-number`、`el-autocomplete` 必须具备 i18n placeholder。确无占位语义时添加 `data-placeholder-exempt`，并以相邻中文注释说明原因。
- 行内查询表单中，查询、重置、导出、视图切换等每个独立操作各占一个无标签 `el-form-item`；禁止在同一无标签 `el-form-item` 内堆叠多个 `el-button` 或 `el-radio-group`。间距只由表单 `gap` 管理，不使用按钮相邻 margin 或负 `margin-bottom` 补偿。
- 交付前必须运行 `scripts/check-project-rules.ps1 -ProjectPath <项目路径> -StrictUiContracts`。直接中文、缺少 placeholder、i18n key 未在 zh/en 同步、或已声明 `@dictKey` 字段的 `*Name` 直出均为错误，不得进入 build 或交付。
