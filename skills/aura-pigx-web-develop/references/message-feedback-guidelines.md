# 消息提示与消息弹出框规范

## 唯一入口

所有业务页面、业务组件、Store、Composable 和工具函数只能从项目统一 Hook 导入：

```ts
import { useMessage, useMessageBox } from '/@/hooks/message';
```

`/@/hooks/message.ts` 是框架维护的统一实现边界。业务任务只调用公开 API，不复制、不改写、不二次封装。

## 标准用法

```ts
import { useMessage, useMessageBox } from '/@/hooks/message';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const handleDelete = async (ids: Array<string | number>) => {
  try {
    await useMessageBox().confirm(t('common.delConfirmText'));
  } catch {
    // 用户主动取消确认，无需错误提示
    return;
  }

  try {
    await delObjs(ids);
    useMessage().success(t('common.delSuccessText'));
  } catch (err: any) {
    useMessage().error(err.msg);
  }
};
```

消息提示：

```ts
useMessage().info(t('message.info'));
useMessage().warning(t('message.warning'));
useMessage().success(t('common.optSuccessText'));
useMessage().error(t('message.operationFailed'));
```

消息弹出框：

```ts
await useMessageBox().confirm(t('common.delConfirmText'));
await useMessageBox().warning(t('message.warning'));
await useMessageBox().prompt(t('message.inputTip'));
```

## 禁止写法

- 禁止从 `element-plus` 导入 `ElMessage`、`ElMessageBox`、`Message` 或 `MessageBox`。
- 禁止直接调用 Element Plus 的消息和弹框 API。
- 禁止自行开发 Toast、消息弹层、通知队列或重复消息 Hook。
- 禁止使用 `const { message, messageBox } = useMessage()`；`useMessage()` 不返回这两个字段。
- 禁止使用其他 UI 库的消息组件绕过项目统一样式、i18n 和交互约定。
- 禁止在业务代码中复制 `/@/hooks/message.ts` 的底层 Element Plus 实现。

## 异常与取消

- 用户取消 `confirm` 属于正常分支，捕获后直接返回，并用中文注释解释无需提示。
- 仅用户主动发起且改变服务端状态的操作在请求失败时调用 `useMessage().error(...)`，包括新增、编辑、删除、启停、保存、提交、导入和其他业务变更操作。
- 字典、下拉选项、列表、详情、初始化、刷新等只读数据加载，`catch` 中禁止调用 `useMessage()`；需要捕获时只维护局部错误态、空态或重试状态，或继续向上抛出交由上层统一处理。
- 请求失败按项目当前错误对象契约读取消息；字段不明确时先检查请求封装和相邻模块，不自行添加多字段兜底。
- 用户可见的固定消息使用 `t()` / `$t()`。
- API 层通常只返回 Promise，不重复弹出页面级成功提示。

### 变更操作与只读加载示例

```ts
// 保存会改变服务端状态，失败时需要向发起操作的用户反馈。
const handleSave = async () => {
  try {
    await saveDevice(formData);
    useMessage().success(t('common.optSuccessText'));
  } catch (err: any) {
    useMessage().error(err.msg);
  }
};

// 下拉加载失败仅影响当前字段可选项，不以全局消息打断用户操作。
const loadDeviceOptions = async () => {
  try {
    deviceOptions.value = await fetchDeviceOptions();
  } catch {
    deviceOptions.value = [];
    optionsLoadFailed.value = true;
  }
};
```

## 评审检查

```powershell
rg "ElMessage|ElMessageBox|MessageBox" src
rg "from ['\"]element-plus['\"]" src
rg "\{\s*message\s*,\s*messageBox\s*\}\s*=\s*useMessage" src
```

命中后逐项判断：框架自带 `src/hooks/message.ts` 可作为底层实现存在；其他业务代码必须改用统一 Hook。
