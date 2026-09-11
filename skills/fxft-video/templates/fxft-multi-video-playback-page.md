# 多路回放模板

```vue
<script setup lang="ts">
import { ref } from 'vue'
import type { WebVideoChannel } from '@fxft/ui-plus'

const channels = ref<WebVideoChannel[]>([
  { id: 'record-01', title: '一号录像', source: { protocol: 'native', url: '/records/01.mp4', kind: 'playback' } },
  { id: 'vod-02', title: '二号点播', source: { protocol: 'hls', url: '/vod/02.m3u8', kind: 'vod' } },
])
</script>

<template>
  <FxftWebMultiVideo
    :channels="channels"
    :layout="{ columns: 2 }"
    @channel-time-update="saveProgress($event.channel.id, $event.time)"
    @channel-error="reportError($event.channel.id, $event.error)"
  />
</template>
```

按 `channel.id` 保存每路进度与错误，不依赖当前槽位。
