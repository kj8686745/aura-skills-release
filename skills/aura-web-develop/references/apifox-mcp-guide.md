# Apifox MCP 联调指南

## 配置 Apifox MCP

在 Claude Code 的 MCP 配置文件（`~/.claude/mcp.json` 或项目级 `.claude/mcp.json`）中添加：

```json
{
  "mcpServers": {
    "apifox": {
      "command": "npx",
      "args": ["-y", "@apifox/mcp-server"],
      "env": {
        "APIFOX_ACCESS_TOKEN": "<你的 Apifox Personal Access Token>"
      }
    }
  }
}
```

获取 Token：Apifox → 头像 → 账号设置 → API 访问令牌 → 新建令牌。

---

## 可用 MCP 工具清单

| 工具名 | 用途 |
|---|---|
| `apifox_list_projects` | 列出所有项目 |
| `apifox_list_apis` | 列出项目下的接口列表 |
| `apifox_get_api_detail` | 获取单个接口的完整定义（含参数、响应体结构）|
| `apifox_search_api` | 按关键词搜索接口 |
| `apifox_run_api_case` | 执行接口测试用例 |
| `apifox_get_schemas` | 获取数据模型定义 |

---

## 联调前准备

1. **确认项目 ID**：调用 `apifox_list_projects` 获取当前业务对应的 Apifox 项目 ID
2. **确认接口路径**：与后端开发确认接口是否已在 Apifox 中定义
3. **确认本地代理**：`pnpm dev` 已启动，`/api` 代理指向正确的后端地址

---

## 联调工作流（详见 `recipes/apifox-workflow.md`）

```
apifox_search_api(关键词)
  → apifox_get_api_detail(apiId)
  → 生成/校验本地 API 模块
  → apifox_run_api_case(caseId) 或直接发请求
  → 修正差异 → 确认通过
```

---

## 常见 Token 作用域

| 操作 | 所需权限 |
|---|---|
| 读取接口定义 | 只读（Read） |
| 执行测试用例 | 可执行（Execute） |
| 修改接口文档 | 写入（Write），一般不需要 |

---

## MCP 不可用时的降级方案

1. 提示用户确认 MCP 配置
2. 手动方式：生成 API 代码后，用户在 Apifox 中手动执行对应测试用例
3. 在交付格式中注明"Apifox MCP 不可用，联调需手动验证"
