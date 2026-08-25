# 通用封装补齐配方

## 必须补齐清单

| 能力 | 内置封装 | 当前项目落点 | 状态 |
|------|----------|--------------|------|
| 表格分页 | `hooks/table.ts` | `src/hooks/table.ts` | 已补齐并适配 |
| 图表 | `hooks/echarts.ts` | `src/hooks/echarts.ts` | 已补齐并适配；需要 `echarts` 依赖 |
| 消息弹窗 | `hooks/message.ts` | `src/hooks/message.ts` | 已补齐并适配，绑定 app context |
| 表单 | `hooks/form.ts` | `src/hooks/form.ts` | 已补齐并适配 |
| 字典 | `src/hooks/dict.ts` | 待补齐 | 依赖 dict store 和 aura-core API，不能直接复制 |
| 参数 | `src/hooks/param.ts` | 待补齐 | 依赖 param store 和 aura-core API，不能直接复制 |
| Pagination | `src/components/Pagination/index.vue` | 待补齐 | 表格页需要分页组件时补齐 |
| RightToolbar | `src/components/RightToolbar/index.vue` | 待补齐 | 查询表格工具栏需要时补齐 |
| DictTag/DictSelect | `src/components/DictTag/` | 待补齐 | 字典体系补齐后补齐 |
| QueryTree | `src/components/QueryTree/index.vue` | 待补齐 | 左树右表页需要时补齐 |

## 补齐步骤

1. 读取内置标准封装和它的直接依赖。
2. 列出依赖中当前项目不存在的模块。
3. 将 `/@/` 改为 `@/`。
4. 去除 `aura-core`、旧 i18n、旧 store 等当前项目不存在依赖，或先补齐依赖。
5. 保留对外 API 名称，便于知识库页面模式复用。
6. 运行类型检查/构建。
7. 将新增封装写回本技能 `references/` 或 `recipes/`。

## 禁止

- 不得原样复制会导致编译失败的封装。
- 不得在没有用户授权时安装新依赖。
- 不得绕过当前项目的 `aura` namespace 和 `.foundation-dev-web` 隔离。
