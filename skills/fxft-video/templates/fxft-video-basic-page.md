# 单路基础模板

```vue
<script setup lang="ts">
import { computed, ref } from 'vue'
import { FxftWebVideo } from '@fxft/ui-plus'
import type { WebVideoSource } from '@fxft/ui-plus'

const source = ref<WebVideoSource | null>(null)
const loading = ref(false)
const requestError = ref('')
const emptyText = computed(() => loading.value ? '正在获取视频...' : requestError.value || '暂无视频源')

async function loadSource() {
  loading.value = true
  requestError.value = ''
  try {
    source.value = await fetchVideoSource()
  } catch {
    source.value = null
    requestError.value = '视频地址获取失败'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <FxftWebVideo
    title="东门摄像机"
    :source="source"
    :empty-text="emptyText"
    :features="{ snapshot: true, zoom: true, metrics: true }"
    @state-change="onStateChange"
    @error="reportPlaybackError"
  />
</template>
```

容器必须有明确宽高。请求错误通过 `emptyText` 显示，不再弹消息；点播只需把 Source 的 `kind` 改为 `vod`。
