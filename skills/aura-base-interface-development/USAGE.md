# 接口契约与联调技能使用说明

按业务模块编写接口文档、核对前后端契约或准备联调时，提供模块、现有 Controller/请求封装和实际部署路径；也可显式调用 `$aura-base-interface-development`。

示例：`$aura-base-interface-development 根据当前公共参数模块的实际接口编制一份完整模块接口文档，标明待联调项。`

对外 API 示例：`$aura-base-interface-development 为设备查询 OpenAPI 编制模块接口契约；响应和分页与内部接口保持一致，列明认证、网关路径及公开字段。`

普通存量模块文档可以直接维护；需要独立审查规范偏差时使用 `$aura-backend-compliance-review`。新增或变更接口契约默认同步既有模块文档，没有时在模块 `docs/` 建立并加入项目文档入口。

接口方法、响应和权限以当前代码与随包规范核对；静态文档不能替代真实接口调用。

## 脚本调用

需要 PowerShell 7。脚本随技能提供，从当前技能目录运行；项目和模块路径使用实际输入。默认只读源码，只有显式 `OutputPath` 才保存盘点结果，建议放临时工作目录。

```powershell
# 扫描明确模块，保存详细结果，终端只输出数量与完成状态。
./scripts/inventory-api-contracts.ps1 -ProjectPath <项目根> -ModulePath 'device-service/src/main' -OutputPath <临时目录>/device-api.json
# 用同范围盘点核对模块文档。
./scripts/check-api-document.ps1 -DocumentPath <模块目录>/docs/接口文档.md -InventoryPath <临时目录>/device-api.json -Json
```

盘点 `routes` 包含方法、路径、Controller/方法名、参数绑定、返回类型、直接平台注解和源码位置；`unresolved` 保留无法静态解析的项。多路径会展开；Controller 映射不代表最终网关访问路径。只读选中接口的盘点和源码，再沿 DTO 与调用链补充字段和行为，不能把 Java 类型名当作字段说明。

文档检查支持 HTTP 总览表（接口编号、方法、路径）、“接口逐项契约：API-…”卡片及“接口逐项契约”下的编号分组；单接口可用基本信息表明确编号和方法路径。共同认证、响应等内容可在模块层维护。它核对已识别的总览、参数表、完整 JSON 响应和代码映射，不执行真实请求。复杂媒体约束、继承、自定义注解、动态路径、实时协议和 DTO 内部字段保留人工/AI 核对；无法定位的组织形式记为未解析，不把版式差异直接判成内容缺失。盘点默认排除构建目录、依赖目录和 `src/test`，实际范围在输出中列明。

退出 `0` 表示所请求的静态盘点/结构核对完成；`1` 表示确定问题或输入失败；`2` 表示未解析或证据不足。先读摘要和问题，再定位必要代码。脚本通过后仍需核对业务语义、字段完整性和联调状态。
