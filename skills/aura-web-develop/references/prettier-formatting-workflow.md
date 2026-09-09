# Prettier 代码格式化流程

## 触发时机

每次新增、修改或重构代码完成后自动执行一次，且必须早于 build、typecheck、lint 和浏览器验证。纯阅读、只改配置说明或只改二进制资源的任务不触发代码格式化。

## 执行规则

1. 读取项目的 `package.json`、锁文件、Prettier 配置和 `.prettierignore`。
2. 优先使用项目已有且明确调用 Prettier 的 `format` 或 `format:write` 脚本。
3. 没有可用脚本时，使用项目本地安装的 Prettier，并通过当前项目包管理器执行：`pnpm exec prettier --write`、`npm exec -- prettier --write` 或 `yarn prettier --write`。
4. 默认只格式化本次修改的 `.js`、`.jsx`、`.ts`、`.tsx`、`.vue`、`.css`、`.scss`、`.less`、`.json`、`.md`、`.yaml` 和 `.yml` 文件；遵循 `.prettierignore`，跳过锁文件、生成物和第三方目录。
5. 项目未安装本地 Prettier 时不得静默安装或改用全局版本；记录未执行原因并继续其他不依赖格式化的验证。
6. 格式化后执行 `git diff --check`，确认没有空白错误，再进入后续验证。
