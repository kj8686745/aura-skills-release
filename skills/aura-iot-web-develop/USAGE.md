# aura-iot-devWeb-develop 使用说明

## 1. 适用场景

当任务涉及以下任意内容时，必须使用本技能：

- 新增或修改业务页面。
- 新增或修改路由。
- 新增或修改接口封装。
- 新增或修改 Pinia 状态。
- 新增或修改 Element Plus 组件交互。
- 新增或修改 Tailwind / SCSS 样式。
- 新增或修改 qiankun 子应用适配逻辑。
- 新增或修改 hooks、公共组件、页面模块组件。
- 需要 VueUse、浏览器验证、UI/UX 评审等辅助能力。

## 2. 标准使用流程

### 第一步：识别任务类型

先判断任务属于：

- 页面开发
- 表格页
- 弹窗表单
- 看板图表
- 路由接入
- API 封装
- 公共组件
- 样式改造
- hooks 补齐
- 页面验证

### 第二步：读取入口资料

任意业务开发必须读取：

```text
SKILL.md
references/project-profile.md
references/css-tailwind-guidelines.md
references/naming-conventions.md
checklists/pre-development.md
```

### 第三步：新页面先查模板

新页面或新模块必须先读取：

```text
templates/README.md
```

如果命中模板，再读取对应模板：

```text
templates/query-table-page.md
templates/dialog-form.md
templates/dashboard-chart-card.md
templates/api-module.md
templates/pinia-store.md
templates/components/README.md
```

如果没有命中具体页面模板、没有可参考模板结构，Agent 必须先调用 `/frontend-design` 完成页面设计，再根据需求和规范实现；不得硬套固定结构。

### 第四步：按任务读取专题资料

| 任务 | 必须读取 |
|------|----------|
| 查询表格 | `templates/query-table-page.md`、`recipes/hooks-standards.md` |
| 弹窗表单 | `templates/dialog-form.md`、`recipes/hooks-standards.md` |
| 图表看板 | `templates/dashboard-chart-card.md`、`recipes/hooks-standards.md` |
| API 封装 | `templates/api-module.md`、`references/naming-conventions.md`、`src/api/index.ts`、`src/utils/request.ts` |
| Pinia 状态 | `templates/pinia-store.md`、`references/naming-conventions.md`、`src/stores/user.ts` |
| 公共组件 | `templates/components/README.md`、命中的具体组件模板、`references/component-and-style-guidelines.md` |
| 组件拆分 | `references/component-and-style-guidelines.md` |
| 样式开发 | `references/css-tailwind-guidelines.md`、`examples/` |
| 命名规范 | `references/naming-conventions.md` |
| 模板与示例边界 | `references/template-vs-example-guidelines.md` |
| VueUse | `/vueuse-functions`、`recipes/vueuse-decision-guide.md` |
| 页面验证 | `/agent-browser`、`checklists/validation.md` |
| 无模板页面设计 | `/frontend-design` |
| UI/UX 评审 | `/ui-ux-pro-max` |

## 3. 强制开发规则

### 3.1 文件分层

- 页面必须放在 `src/views/`。
- API 必须放在 `src/api/`。
- 页面不得直接使用 axios。
- 跨页面共享状态才进入 `src/stores/`。
- 公共组件放在 `src/components/`，必须按 `templates/components/README.md` 选择合适场景模板。
- 页面模块私有组件放在页面目录的 `components/`。
- 页面模块私有样式较多时放在页面目录的 `styles/`。

### 3.2 命名规则

- 新增 API、页面、路由、组件、store、hooks、样式文件必须按 `references/naming-conventions.md` 命名。
- API 文件名必须体现业务域和业务对象，不能使用 `api.ts`、`online.ts`、`common.ts` 等过泛命名。
- 页面目录/文件、路由 path/name/meta.title 必须保持业务一致。
- 组件、store、hooks 名称必须体现职责和业务对象。

### 3.3 模板规则

- 命中预设模板时必须按模板落地。
- 未命中具体页面模板、没有可参考模板结构时，必须调用 `/frontend-design` 完成页面设计。
- 没有新增/编辑弹窗需求，不得创建 `form.vue`。
- 没有详情/抽屉需求，不得创建 `detail.vue` / `drawer.vue`。
- 有跨页面复用场景的区块必须沉淀为公共组件。

### 3.4 Hooks 规则

- 查询表格必须使用 `src/hooks/table.ts` 的 `useTable`。
- 图表必须使用 `src/hooks/echarts.ts` 的 `useECharts`。
- 消息和确认框必须使用 `src/hooks/message.ts`。
- 表单重置必须使用 `src/hooks/form.ts`。

### 3.5 CSS 规则

- 能用 Tailwind 的样式必须用 Tailwind。
- Tailwind 表达不了的情况才写 SCSS。
- Tailwind 颜色必须绑定 Element Plus 主题变量。
- SCSS 颜色也必须使用 Element Plus CSS 变量。
- 不得硬编码主题色。
- 跨页面公共样式写入 `src/styles/page.scss`。
- 页面模块私有样式较多时写入 `src/views/<module>/<page>/styles/`。

### 3.6 VueUse 规则

以下场景必须先调用 `/vueuse-functions`：

- DOM 监听
- 浏览器 API
- 防抖节流
- 定时器和轮询
- 异步状态
- 本地存储
- 复杂 watch
- 虚拟列表

## 4. 验证流程

开发完成后必须按变更范围验证：

```bash
pnpm build
pnpm lint
pnpm dev:qiankun
```

页面、路由、交互、样式变更必须使用 `/agent-browser` 验证：

- 页面核心文本。
- 路由跳转。
- 表格/表单/弹窗/图表核心交互。
- 控制台错误。
- 登录态或 token 场景不得猜测、伪造或绕过。

## 5. 交付格式

每次完成任务后按以下格式交付：

```md
## 完成内容
- ...

## 使用的技能资料
- templates/...
- references/...
- checklists/...

## 项目适配点
- ...
- 命名依据：API / 页面 / 路由 / 组件 / store / hooks / 样式文件为什么这样命名

## 复用封装
- useTable / useECharts / useMessageBox / useForm / VueUse 函数

## CSS 说明
- Tailwind 使用范围
- SCSS 使用原因
- Element Plus 主题变量

## 验证结果
- pnpm build: ...
- agent-browser: ...

## 剩余风险
- ...
```

## 6. 维护方式

- 规范更新写入 `knowledge/`、`references/`、`checklists/`、`recipes/`。
- 示例代码写入 `examples/`。
- 脚本写入 `scripts/`。
- 不把规范重新放回业务项目文档目录中维护。
