# 文件与实时交互技能使用说明

业务需要 Excel、SSE、WebSocket、Socket.IO、组合文件任务，或核对下载任务模块的接入状态时，说明数据来源、规模和项目依赖；也可显式调用 `$aura-cap-file-realtime-use`。Socket.IO 请提供实际公共模块版本、应用对外路径、namespace、认证方式和部署实例数。单独文件存储接入使用 `$aura-cap-base-use`。

示例：`$aura-cap-file-realtime-use 为当前分组列表选择同步 Excel 导出方式，核对已有注解与权限边界。`

定时任务和调度器不属于本技能；不同文件和实时场景按任务读取对应资料。
