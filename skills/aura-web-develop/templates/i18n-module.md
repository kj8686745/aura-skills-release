# i18n 模块文件模板

## 文件位置与分层

```
# 同一业务域跨页面复用
src/views/<业务域>/i18n/
├── zh-cn.ts
└── en.ts

# 仅当前业务模块专属
src/views/<业务域>/<业务模块>/i18n/
├── zh-cn.ts
└── en.ts
```

## 复用原则

新增文案按“全项目 → 业务域 → 当前模块”搜索。全项目通用 key 复用 `src/i18n/`；同一业务域两个及以上页面共用的 key 放入 `src/views/<业务域>/i18n/`；只有页面专属文案才放入模块文件，禁止重复定义同义文案。

| 场景 | 使用 |
|---|---|
| 查询按钮 | `$t('common.queryBtn')` |
| 新增按钮 | `$t('common.addBtn')` |
| 清空筛选按钮 | `$t('<业务域>.clearFilter')` 或已有全局 key |
| 操作列标题 | `$t('common.action')` |
| 编辑按钮 | `$t('common.editBtn')` |
| 删除按钮 | `$t('common.delBtn')` |
| 操作成功 | `$t('common.optSuccessText')` |
| 删除成功 | `$t('common.delSuccessText')` |

完整公共 key 见 `src/i18n/pages/form/zh-cn.ts`。

## zh-cn.ts 模板

```ts
// src/views/<业务域>/i18n/zh-cn.ts（跨模块复用）
export default {
  <业务域短名>: {
    clearFilter: '清空筛选',
    loadFailed: '加载失败',
  },
}
```

## en.ts 模板

```ts
// src/views/<业务域>/<业务模块>/i18n/zh-cn.ts（页面专属）
export default {
  <模块短名>: {
    ruleName: 'Rule Name',
    ruleCode: 'Rule Code',
    statusEnabled: 'Enabled',
    statusDisabled: 'Disabled',
    publishRule: 'Publish Rule',
    ruleNamePlaceholder: 'Enter rule name',
  },
}
```

同样为业务域和页面专属 key 分别维护 `en.ts`，禁止只更新一种语言。

## 组件中使用

```vue
<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
</script>

<template>
  <!-- 模板中用 $t -->
  <el-input :placeholder="$t('<模块短名>.ruleNamePlaceholder')" />

  <!-- script 中用 t() -->
  <el-button>{{ $t('common.queryBtn') }}</el-button>
</template>
```

## Key 命名规则

- 格式：`<模块短名>.<功能描述>`，camelCase
- 模块短名取业务对象，如 `ruleConfig`、`wxAccount`、`payChannel`
- 禁止用拼音或无意义缩写
