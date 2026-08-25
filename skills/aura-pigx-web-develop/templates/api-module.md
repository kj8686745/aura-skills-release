# API 模块模板入口

API 封装以以下资料为准：

- `../knowledge/PIGX前端开发规范/工程与代码生成规范.md`
- 当前业务域 `src/api/` 相邻模块
- 当前接口文档、Apifox 定义和真实 TypeScript 类型
- `/@/utils/request` 的实际调用契约

## 强制规则

- 业务请求统一使用 `/@/utils/request`，不直接创建 axios 实例。
- 函数命名遵循当前业务域和最新版页面模式，不强行套用历史技能命名。
- API、类型、页面和子组件职责分离。
- 不硬编码域名、IP、Token、Cookie、密码或部署前缀。
- 已明确的字段名、类型和单值/数组结构不得自行增加旧字段兜底。
- 每个 API 函数添加简体中文用途注释；特殊 Header、Blob、上传或兼容契约说明来源。

API 层通常不弹出页面级成功消息；页面需要反馈时只能从 `/@/hooks/message` 使用 `useMessage` / `useMessageBox`。
