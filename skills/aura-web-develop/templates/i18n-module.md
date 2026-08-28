# i18n 模块文件模板

## 文件位置

```
src/views/<业务域>/<业务模块>/i18n/
├── zh-cn.ts
└── en.ts
```

## 复用原则

**优先使用已有公共 key**，不在模块文件中重复定义：

| 场景 | 使用 |
|---|---|
| 查询按钮 | `$t('common.queryBtn')` |
| 新增按钮 | `$t('common.addBtn')` |
| 重置按钮 | `$t('common.resetBtn')` |
| 操作列标题 | `$t('common.action')` |
| 编辑按钮 | `$t('common.editBtn')` |
| 删除按钮 | `$t('common.delBtn')` |
| 操作成功 | `$t('common.optSuccessText')` |
| 删除成功 | `$t('common.delSuccessText')` |

完整公共 key 见 `src/i18n/pages/form/zh-cn.ts`。

## zh-cn.ts 模板

```ts
// src/views/<业务域>/<业务模块>/i18n/zh-cn.ts
export default {
  // key 命名：<模块短名>.<功能描述>，camelCase
  <模块短名>: {
    // 字段名
    ruleName: '规则名称',
    ruleCode: '规则编码',
    // 状态
    statusEnabled: '已启用',
    statusDisabled: '已停用',
    // 操作
    publishRule: '发布规则',
    // placeholder
    ruleNamePlaceholder: '请输入规则名称',
  },
}
```

## en.ts 模板

```ts
// src/views/<业务域>/<业务模块>/i18n/en.ts
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
