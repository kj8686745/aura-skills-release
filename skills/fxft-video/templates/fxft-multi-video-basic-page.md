# 多路基础模板

```vue
<script setup lang="ts">
import { ref } from 'vue'
import { FxftWebMultiVideo } from '@fxft/ui-plus'
import type { WebVideoChannel, WebVideoWallLayout } from '@fxft/ui-plus'

const selectedId = ref('camera-01')
const selectedIds = ref(['camera-01'])
const layout = ref<WebVideoWallLayout>({ columns: 2 })
const loading = ref(false)
const channels = ref<WebVideoChannel[]>([
  { id: 'camera-01', title: '东门', source: { protocol: 'hls', url: '/live/01.m3u8', kind: 'live' } },
  { id: 'camera-02', title: '西门', autoplay: false, source: null, emptyText: '西门视频地址获取失败' },
])
</script>

<template>
  <div v-loading="loading" class="video-wall-region">
    <FxftWebMultiVideo
      v-model:selected-id="selectedId"
      v-model:selected-ids="selectedIds"
      :channels="channels"
      :layout="layout"
      empty-text="暂无视频源"
      :features="{ ptz: true, snapshot: true, removeChannel: true }"
      @layout-change="layout = $event"
      @reorder="channels = $event.channels"
      @remove-channel="channels = channels.filter(item => !$event.ids.includes(item.id))"
    />
  </div>
</template>
```

`v-loading` 需要按项目现有 Element Plus 方式注册指令和样式。布局支持 1/4/6/9/16 分屏。普通点击单选，Ctrl 点击多选。
