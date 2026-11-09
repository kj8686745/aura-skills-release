# 公司组件库下载与安装

适用于 `@fxft/aura-ui` 及地图、视频按需使用的 `@fxft/ui-plus`。公司 npm 私服配置使用脱敏模板 [`.npmrc.example`](./.npmrc.example)，保留 `${FXFT_NPM_AUTH}` 环境变量引用，由本机或 CI 的安全配置提供已获授权的认证值，不将真实凭据写入项目文件或输出到日志。

先读取项目 `package.json`、锁文件和实际安装包，沿用现有包管理器；已有且满足组件需求时直接复用。需要新增或升级时，核对目标包的公开能力和依赖兼容性，确定项目采用的精确版本，不自动选择 `latest`。

执行包管理器命令前遵守用户及项目授权规则；未授权时说明原因、影响和完整命令，获得授权后执行，已明确授权的同一操作不重复询问。下文命令中的 `<目标版本>` 必须替换为已确认的精确版本。

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

返回 `False` 时，将本目录的 `.npmrc.example` 复制到用户目录：

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

按项目包管理器查询实际目标包，例如：

```bash
pnpm info "@fxft/aura-ui@<目标版本>" version dist.tarball peerDependencies
npm view "@fxft/aura-ui@<目标版本>" version dist.tarball peerDependencies
```

选择匹配的一条命令。需要 `@fxft/ui-plus` 时替换包名并单独检查，不以其他包的结果代替。核对返回版本、依赖约束和 `dist.tarball`；tarball 可以经 `npm-store` 或 `npm-public` 仓库组返回。元数据查询成功仅证明可读取包信息，实际下载仍以安装结果为准。

常见失败：

| 错误 | 处理方式 |
| --- | --- |
| `E401` | 检查是否合并了公司私服认证项 |
| `E403` | 联系管理员开通 `npm-public` 读取权限 |
| `E404` | 检查 `@fxft:registry`、包名和版本；部分权限问题也可能返回404 |
| `ENOTFOUND`、`ETIMEDOUT` | 检查公司网络、VPN、DNS或代理 |

## 五、安装与接入

按项目现有包管理器选择一条命令，组件库作为运行依赖安装：

```bash
pnpm add --save-exact "@fxft/aura-ui@<目标版本>"
npm install --save-exact "@fxft/aura-ui@<目标版本>"
yarn add --exact "@fxft/aura-ui@<目标版本>"
```

`@fxft/ui-plus` 仅在专项需求命中时替换包名安装。选择 Resolver 且项目缺少 `unplugin-vue-components` 时，按项目兼容版本补为开发依赖；已有插件直接合并配置，不重复安装或覆盖。

安装后核对 `package.json`、对应锁文件与实际安装版本一致，确认所用组件的 exports、类型、JS/CSS 和所选方案的 Resolver 入口存在；依赖冲突按兼容要求处理，不通过强制忽略冲突完成接入。安装或权限失败时说明原因，不把未安装的组件标记为可运行。

Aura UI 继续按 [接入规范](../aura-ui能力清单与接入规范.md) 完成导入、样式、语言和项目服务绑定；地图、视频按对应专项规范接入。构建和页面验证按用户授权执行，交付注明实际验证范围。

该 `.npmrc.example` 仅限公司内部使用，不得对外分发；由模板生成的含认证值 `.npmrc` 不得提交到代码仓库或对外分发。
