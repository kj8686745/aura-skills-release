# AuraVideoPlayer 视频播放器

公共子入口 `@fxft/aura-ui/video-player`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

播放视频文件，支持封面、尺寸配置及 ref 播放控制。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraVideoPlayer from '@fxft/aura-ui/video-player';
</script>

<template>
  <AuraVideoPlayer src="/REPLACE_WITH_VIDEO_URL.mp4" width="100%" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 必填 | 默认值 |
| --- | --- | --- | --- | --- |
| src | 视频文件的 URL | `string` | 是 | `undefined` |
| width | 播放器宽度 | `string` | 否 | `undefined` |
| height | 播放器高度 | `string` | 否 | `undefined` |
| poster | 视频封面图片 URL | `string` | 否 | `undefined` |

## Methods

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| play | 挂载后调用底层 play，不返回媒体播放 Promise | 无 | void |
| pause | 挂载后调用底层 pause；未初始化时调用可能报错 | 无 | void |

## 内置配置

| 配置项 | 默认值 | 说明 |
| ------ | ------ | ---- |
| 主题色 | 初始化 `#ff8100`，挂载时读取 `--el-color-primary`，为空时回退 `#409eff` | 播放器主题颜色 |
| 静音 | `false` | 是否默认静音 |
| 网页全屏 | `false` | 是否支持网页全屏 |
| 播放倍速 | `['0.75', '1.0', '1.25', '1.5', '2.0']` | 可选的播放倍速列表 |
| 自动播放 | `false` | 是否自动播放 |
| 循环播放 | `false` | 是否循环播放 |
| 镜像画面 | `false` | 是否默认开启镜像 |
| 关灯模式 | `false` | 是否默认开启关灯模式 |
| 默认音量 | `0.3` | 默认音量大小（0-1） |
| 显示控制器 | `true` | 是否显示播放控制器 |
| 视频标题 | `''` | 视频标题文本 |

## 注意事项

- src 可动态更新；width、height、poster 按底层初始化配置生效，主题色只在挂载时读取 --el-color-primary。
- 公开播放控制为 play、pause；没有对外发送 play、pause、timeupdate、canplay 事件。
- 依赖浏览器媒体能力和可访问的视频地址，自动播放受浏览器策略限制。卸载会暂停播放，但未提供完整的 HLS 资源销毁接口。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { DefineComponent } from 'vue';

declare const AuraVideoPlayer: DefineComponent<{
  src: string;
  width?: string;
  height?: string;
  poster?: string;
}, { play: () => void; pause: () => void }>;

export default AuraVideoPlayer;
```

API 资料来自 `docs/component/video-player.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
