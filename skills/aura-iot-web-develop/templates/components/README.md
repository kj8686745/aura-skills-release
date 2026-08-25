# 公共组件模板索引

## 使用原则

公共组件不是默认选项。开发前先判断复用范围：

| 复用范围 | 放置位置 |
|----------|----------|
| 只在当前页面使用 | `src/views/<module>/<page>/components/` |
| 当前模块多个页面复用 | 当前模块组件目录或页面模块 `components/` |
| 跨模块、跨页面复用 | `src/components/<ComponentName>/index.vue` |

不确定是否复用时，先放页面内；第二次真实复用时再抽到公共组件。

## 场景模板

| 模板 | 适用场景 |
|------|----------|
| `base-display-component.md` | 状态标签、信息块、空状态、只读展示组件 |
| `define-model-component.md` | 输入、选择、开关、筛选条件等双向绑定组件 |
| `slots-container-component.md` | 卡片容器、工具栏、列表容器、可扩展布局 |
| `form-field-component.md` | 封装 Element Plus 表单项、复合输入项 |
| `dialog-drawer-component.md` | 新增/编辑弹窗、详情抽屉、确认操作容器 |
| `list-card-component.md` | 列表卡片、指标卡片、可操作数据块 |

## 公共组件目录建议

```text
src/components/<ComponentName>/
├── index.vue
├── types.ts        # 可选：复杂类型
└── useXxx.ts       # 可选：组件内部组合逻辑
```

## 强制规则

- props、emits、slots 必须有类型定义或明确说明。
- 公共组件不得直接耦合某个页面 API。
- 文案、权限、接口路径不得写死到公共组件中。
- 样式以 Tailwind 为主；颜色、背景、边框、阴影必须使用 Element Plus CSS 变量。
- 组件注释、文档和错误提示必须使用简体中文。
