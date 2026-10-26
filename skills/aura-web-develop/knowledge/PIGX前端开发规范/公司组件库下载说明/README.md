# 公司 UI 规范下载配置

`@fxft/ui-plus` 存放在公司 npm 私服。使用前需要配置 `.npmrc`，本目录提供脱敏模板 [`.npmrc.example`](./.npmrc.example)。复制后将 `${FXFT_NPM_AUTH}` 替换为已获授权的私服认证值，认证值不得提交到代码仓库。

## 一、放在项目根目录

将 `.npmrc.example` 复制为业务项目根目录的 `.npmrc`，与 `package.json`、lock 文件同级：

```text
业务项目/
├── .npmrc
├── package.json
├── pnpm-lock.yaml
└── src/
```

这种方式只对当前项目生效，适合项目统一携带私服配置。

如果项目根目录已经存在 `.npmrc`，不要直接覆盖。打开原文件，将本目录 `.npmrc.example` 中缺少的配置项合并进去；同名配置只保留一份。

## 二、放在用户个人目录

Windows用户级配置位置：

```text
%USERPROFILE%\.npmrc
```

这种方式对当前Windows用户的所有项目生效。

先检查文件是否存在：

```powershell
Test-Path -LiteralPath "$env:USERPROFILE\.npmrc"
```

### 文件不存在

返回 `False` 时，将本目录的 `.npmrc` 复制到用户目录：

```powershell
Copy-Item -LiteralPath '<本说明目录>\.npmrc.example' -Destination "$env:USERPROFILE\.npmrc"
```

### 文件已存在

返回 `True` 时，不要覆盖原文件。打开文件：

```powershell
notepad "$env:USERPROFILE\.npmrc"
```

保留原有 registry、代理、证书和其他 scope 配置，再把本目录 `.npmrc.example` 中缺少的配置项合并进去：

- 已有同名配置时更新原值，不重复添加。
- 没有 `@fxft:registry` 时新增。
- 没有公司私服认证项时新增。
- `always-auth` 保持为 `true`。

项目根和用户目录同时存在 `.npmrc` 时，同名配置以项目根为准。

## 三、检查配置是否生效

在业务项目根目录执行：

```bash
pnpm config get @fxft:registry
```

正常应返回：

```text
https://repository.fxft.online/repository/npm-public/
```

也可以使用 npm检查：

```bash
npm config get @fxft:registry
```

## 四、检查公司私服下载权限

任选一个命令：

```bash
pnpm info @fxft/ui-plus
npm view @fxft/ui-plus
```

正常结果应包含包信息、`dist-tags` 和 `dist.tarball`。核对实际返回版本与项目批准版本，tarball 可以经 `npm-store` 或 `npm-public` 仓库组返回；能够读取项目所需精确版本，才表示对应下载权限正常。不将历史示例版本或 `latest` 自动作为项目升级目标。

常见失败：

| 错误 | 处理方式 |
| --- | --- |
| `E401` | 检查是否合并了公司私服认证项 |
| `E403` | 联系管理员开通 `npm-public` 读取权限 |
| `E404` | 检查 `@fxft:registry`、包名和版本；部分权限问题也可能返回404 |
| `ENOTFOUND`、`ETIMEDOUT` | 检查公司网络、VPN、DNS或代理 |

权限检查成功后，按项目批准的精确版本安装并使用 `--save-exact`，保存对应锁文件。

该 `.npmrc.example` 仅限公司内部使用，不得对外分发；由模板生成的含认证值 `.npmrc` 不得提交到代码仓库或对外分发。
