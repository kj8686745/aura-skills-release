# 开发前检查清单

## 最新规范

- [ ] 已读取 `knowledge/PIGX前端开发规范/README.md`
- [ ] 已读取最新版总览、工程与代码生成规范、开发检查清单
- [ ] 已按任务读取路由、模块联邦、样式资源、组件复用或对应页面模式
- [ ] 未使用旧技能模板覆盖最新版正式规范

## 当前项目事实

- [ ] 已检查 `package.json`、锁文件和实际 Node.js/pnpm 要求
- [ ] 已检查 `vite.config.*`、Module Federation 配置和当前 `remoteName`
- [ ] 已检查 `src/hooks/`、`src/components/index.ts`、相邻页面和相邻 API
- [ ] 已确认路径别名为 `/@/`
- [ ] 已确认独立运行、远程运行或两者都需要验收

## 需求与页面模式

- [ ] 已列出页面、字段、接口、权限、状态、路由/菜单和验收项
- [ ] 新建正式业务页面、菜单入口或操作按钮时，已从路由/组件路径和 `v-auth` 生成页面菜单与按钮权限清单
- [ ] 用户明确指定的权限编码已原样纳入清单；未指定项已按当前项目路由规范和相邻模块的实际 `v-auth` 命名规则生成，并记录依据
- [ ] 菜单权限流程命中时，已读取 `references/admin-menu-permission-workflow.md`；已确认是否具备明确授权、环境、Token、租户和父菜单定位信息
- [ ] 已选择查询表格、查询卡片、左树右表、弹窗表单、详情/抽屉、看板或 Teleport 页面模式
- [ ] 已在编码前列出路由页与页面私有组件职责；两个及以上业务 Dialog/Drawer 已分别规划组件文件，未以“先跑通”为由全部内联到入口页
- [ ] 截图、HTML 原型或 Figma 只作为业务内容和视觉输入，未覆盖 PIGX 工程规范
- [ ] 地图任务已读取 2D 地图规范；视频任务已读取视频规范

## 接口与反馈

- [ ] 已从用户资料、Apifox 或后端定义确认 URL、Method、字段和响应结构
- [ ] 已检查当前业务域 API 命名，不强行套用历史五段式
- [ ] 已确认业务消息统一导入：
  `import { useMessage, useMessageBox } from '/@/hooks/message';`
- [ ] 已确认不会直接引入 Element Plus Message/MessageBox，也不会自行实现消息组件

## 表格与下拉

- [ ] 明确要求表格撑满剩余高度时，已规划纵向 Flex 高度链路、`min-height: 0`、`el-table--fit` 和 `flex: 1`，未计划使用 `100vh` 或固定像素表格高度
- [ ] 新增或修改的普通 `el-select` 已添加 `filterable`；不适用时已记录用户要求或组件不兼容原因

## 注释

- [ ] 已读取 `references/code-comment-guidelines.md`
- [ ] 已识别需要说明的文件头、Props/Emits、API 契约、副作用、兼容和生命周期位置
- [ ] 已确认新增文本使用 UTF-8 无 BOM
