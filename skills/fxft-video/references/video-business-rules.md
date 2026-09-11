# 视频业务规则

## Source 与模式

- 使用判别联合 `WebVideoSource`，不要拆成 `url + playMode`。
- 内容类型只允许 `live`、`playback`、`vod`；旧值 `recording` 和旧模式 `record` 不兼容。
- 本地文件使用 `{ protocol: 'native', file, kind: 'playback' }`。
- WebRTC 只接标准 WHEP；私有信令先由服务端转换。
- 动态接口只返回 FLV/MPEG-TS 地址且无法提供编码信息时，不传 `hasAudio`，交给组件自动识别和音频降级。业务希望优先使用声音时可传 `true`，但音频 codec 不支持仍降级为仅视频；明确只要画面时传 `false`。
- 遇到 `CodecUnsupported` 时先区分音频和视频错误并探测真实编码。桌面播放器可播不代表浏览器 MSE 支持，不建议安装“音频编码插件”或 Codec Pack。
- FLV 中的 G.711A/PCMA 优先在服务端转为 AAC-LC；也可在服务端提供 WebRTC/WHEP 让浏览器协商 PCMA。前端 WASM 解码仅在用户明确要求时评估。

## 状态与重连

- 区分业务数据请求与媒体连接：业务请求发生在播放器拿到 Source 之前，媒体连接状态由组件内部维护。
- 单路业务请求中保持 `source=null`，将 `emptyText` 设为“正在获取视频...”等业务加载文案；请求失败后改为具体错误文本。
- 多路业务请求使用 Element Plus `v-loading` 覆盖整个视频墙区域，不给每个通道重复加 loading。
- 业务请求结束但没有有效 Source，或获取播放地址失败时，通过空态文本显示结果：单路设置组件 `emptyText`，多路设置对应 `channel.emptyText`；多路组件的 `emptyText` 仅作为所有通道和补位槽的统一兜底。不要同时调用 `ElMessage`、toast、Notification 或弹窗。
- 用 `state-change` 和 `error` 驱动业务状态，不读取 DOM 或底层引擎。
- 媒体播放失败使用组件内置 error 状态；业务 `error/channel-error` 回调只记录、上报或提供重试数据，不再叠加消息提示。
- 连接超时和重试耗尽必须进入 error；重试期间可显示最后一帧。
- `buffer` 默认保留约 1 秒可播放数据；直播延迟超过目标缓冲与最大容差之和时由组件追赶直播尾部。业务只通过公开配置覆盖，不操作底层 SourceBuffer。
- 首次连接、尚无上一帧时居中显示 `loadingText`；已经播放并保留上一帧时只显示低干扰缓冲状态。重连、切源、隐藏挂起或销毁导致的 `AbortError` 是预期中断，不应再次计为媒体错误或重复重连。
- `active=false` 用于释放不应激活的窗口；`suspendWhenHidden` 控制不可见时释放资源。
- 切换布局不能重建仍可见的同一 `channel.id` 播放器。

## PTZ

- 仅直播显示 PTZ。按下发 `phase: start` 和具体 `direction`，松开发 `phase: stop`、`direction: stop`。
- `stop` 不得被节流或防抖。连续开始命令可限频，但必须保持第一下立即发出。
- PTZ 回调只转换业务命令和调用 API，不在组件中写厂商协议。

## 多路

- `channel.id` 是唯一稳定身份，槽位序号只用于展示。
- 唯一顺序只由通道增删和 `reorder` 改变；分屏切换只截取容量。
- 单屏显示顺序第一；4/6/9/16 分屏分别显示前 N 路，不足补空态。
- 普通点击单选，`Ctrl + 点击` 追加或取消；Delete/Backspace 仅在视频墙区域内请求删除选中通道。
- 组件不修改受控 `channels`。收到 `remove-channel` 或 `reorder` 后由业务更新数组。
- 开启缩放后，`dragMode='pan'` 拖动画面，`dragMode='window'` 拖动窗口换位；模式互斥且不依赖标题区域。缩回 `1×` 时画面自动回中。

## 浏览器边界

- HLS/FLV 服务器必须配置 CORS；截图还要求媒体允许 Canvas 读取。
- HTTPS 页面不得加载 HTTP/WS 媒体。
- MediaRecorder 只有浏览器支持真实 MP4 MIME 时才可录像，不伪造扩展名。
