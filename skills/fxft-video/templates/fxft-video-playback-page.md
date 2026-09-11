# 单路回放模板

```vue
<script setup lang="ts">
import { ref } from 'vue'
import { FxftWebVideo } from '@fxft/ui-plus'
import type { WebVideoExpose, WebVideoSource } from '@fxft/ui-plus'

const player = ref<WebVideoExpose | null>(null)
const source: WebVideoSource = {
  protocol: 'native',
  url: '/records/camera-01.mp4',
  kind: 'playback',
}
</script>

<template>
  <FxftWebVideo
    ref="player"
    title="录像回放"
    :source="source"
    @time-update="({ currentTime }) => console.log(currentTime)"
  />
</template>
```

用 `player.seek(seconds)` 跳转，用 `setPlaybackRate(rate)` 设置倍速。本地文件改传 `file: File`。
