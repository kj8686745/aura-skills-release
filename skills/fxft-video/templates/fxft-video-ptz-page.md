# 单路 PTZ 模板

```vue
<script setup lang="ts">
import { FxftWebVideo } from '@fxft/ui-plus'
import type { WebVideoPtzEvent, WebVideoSource } from '@fxft/ui-plus'

const source: WebVideoSource = {
  protocol: 'flv',
  url: '/live/ptz-01.flv',
  kind: 'live',
  lowLatency: true,
}

function onPtz(event: WebVideoPtzEvent) {
  // direction 在按下时为具体命令，松开时为 stop。
  sendDevicePtz(event)
}
</script>

<template>
  <FxftWebVideo
    title="球机一号"
    :source="source"
    :features="{ ptz: true, snapshot: true, zoom: true }"
    :ptz-speed="5"
    @ptz-command="onPtz"
  />
</template>
```

PTZ 仅用于 `kind: 'live'`。业务必须立即处理 `phase: 'stop'`，不得对 stop 做节流。
