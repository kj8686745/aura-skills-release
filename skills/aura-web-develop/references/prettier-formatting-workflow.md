# Prettier 代码格式化流程

## 触发时机

触发、范围与时机统一按[检查选择表](development-review-workflow.md#检查选择表)；本页只说明如何使用项目已有格式化工具。纯整理按快速路径保持项目格式，纯阅读或只改二进制资源不触发代码格式化。

## 执行规则

1. 读取项目的 `package.json`、锁文件、Prettier 配置和 `.prettierignore`。
2. 核对项目已有 `format` / `format:write` 是否能限定本次文件；只使用可限定范围的调用，不能直接触发全仓格式化。
3. 没有可用脚本时，使用项目本地安装的 Prettier，并通过当前项目包管理器执行：`pnpm exec prettier --write`、`npm exec -- prettier --write` 或 `yarn prettier --write`。
4. 默认只格式化本次修改的 `.js`、`.jsx`、`.ts`、`.tsx`、`.vue`、`.css`、`.scss`、`.less`、`.json`、`.md`、`.yaml` 和 `.yml` 文件；遵循 `.prettierignore`，跳过锁文件、生成物和第三方目录。
5. 项目未安装本地 Prettier 时不得静默安装或改用全局版本；记录未执行原因并继续其他不依赖格式化的验证。
6. 格式化后对同批文件执行项目本地 Prettier 检查与 `git diff --check`，再进入相应验收。后续仅文档/注释变化不重跑无关业务检查；若格式化改变了已验证代码，重新判断并补跑受影响检查，不能沿用修改前结果。
