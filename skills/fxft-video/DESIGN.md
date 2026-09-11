# 设计说明

2.0 版以 `FxftWebVideo` 和 `FxftWebMultiVideo` 为唯一新业务基线。组件使用浏览器标准媒体能力，并按协议内部选择 HLS、MPEG-TS/FLV 或 WHEP 引擎；业务层只提供结构化 `WebVideoSource`。

技能入口只保留决策与不变量，完整 API 放在 `references/`，可复制实现放在 `templates/`。旧 Jessibuca 组件的脚本、decoder、窗口 index/uuid 和私有实例 API不再属于新版技能契约。
