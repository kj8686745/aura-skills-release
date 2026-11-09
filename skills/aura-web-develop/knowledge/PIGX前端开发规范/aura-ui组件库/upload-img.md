# AuraUploadImg 单图上传

公共子入口 `@fxft/aura-ui/upload-img`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

上传单张图片，支持预览、清空和表单校验。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraUploadImg from '@fxft/aura-ui/upload-img';
import { ref } from 'vue';

const value = ref('');
// 本地演示适配器；生产请替换为真实 httpRequest 或注入 request。
const httpRequest = async () => ({ data: { url: 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22/%3E' } });
</script>

<template>
  <AuraUploadImg v-model="value" :http-request="httpRequest" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| imageUrl | 图片地址 | `string` | `''` | 否 |
| modelValue | 图片地址 (v-model) | `string` | `''` | 否 |
| uploadFileUrl | 上传图片接口路径 | `string` | `'/admin/sys-file/upload'` | 否 |
| drag | 是否支持拖拽上传 | `boolean` | `true` | 否 |
| disabled | 是否禁用上传组件 | `boolean` | `false` | 否 |
| fileSize | 图片大小限制(MB) | `number` | `5` | 否 |
| fileType | 图片类型限制 | `string[]` | `['image/jpeg', 'image/png', 'image/gif']` | 否 |
| height | 组件高度 | `string` | `'150px'` | 否 |
| width | 组件宽度 | `string` | `'150px'` | 否 |
| borderRadius | 组件边框圆角 | `string` | `'8px'` | 否 |
| iconSize | 图标大小 | `number` | `undefined` | 否 |
| dir | 文件目录 | `string` | `''` | 否 |
| baseURL | 拼接原生上传地址的基础地址；预览回退只读本属性，建议提供 getFileUrl | `string` | `undefined` | 否 |
| action | 显式原生上传地址；设置后不使用应用 request | `string` | `undefined` | 否 |
| httpRequest | 自定义上传请求，优先级最高 | `UploadProps['httpRequest']` | `undefined` | 否 |
| beforeUpload | 自定义上传前校验 | `UploadProps['beforeUpload']` | `undefined` | 否 |
| onSuccess | Element Plus onSuccess(response, file, files) 回调 | `UploadProps['onSuccess']` | `undefined` | 否 |
| onError | Element Plus onError(error, file, files) 回调 | `UploadProps['onError']` | `undefined` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:imageUrl | 请求成功或 clear 时第一个触发 | value: string |
| update:modelValue | 紧随 update:imageUrl | value: string |
| change | 两次模型更新后；成功为原始 File，clear 时无参数；随后尝试表单校验 | file?: File |

## Slots

| 插槽名 | 说明 | 参数 |
| --- | --- | --- |
| empty | 未选图片时的内容 | 无 |
| tip | 上传提示 | 无 |

## Methods

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| clear | 清空图片并按更新 imageUrl/modelValue/change 顺序通知；方法自身不检查 disabled | 无 | void |

## v-model

`v-model` 或 `v-model:imageUrl` 绑定图片地址字符串，空值使用 `''`。初始非空 `imageUrl` 优先，后续任一绑定变化都能覆盖显示。

## 注意事项

- 上传优先级：httpRequest → 未指定 action 时使用公共 request → Element Plus 原生上传。默认路径为 /admin/sys-file/upload。原生上传的认证头需单独配置。
- 默认请求提交 file、dir，设置 Enc-Flag: false；模型保存原始地址，getFileUrl 只用于展示。
- 文件大小允许等于 fileSize，类型使用 MIME 精确匹配。limit=1 时替换图片受底层上传列表限制。
- 上传成功和 clear 都会更新绑定值、触发 change 和表单校验；建议只绑定 modelValue 或 imageUrl 中的一种。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';
import type { UploadProps } from 'element-plus';

declare const AuraUploadImg: DefineComponent<{
  imageUrl?: string;
  modelValue?: string;
  uploadFileUrl?: string;
  action?: string;
  baseURL?: string;
  httpRequest?: UploadProps['httpRequest'];
  beforeUpload?: UploadProps['beforeUpload'];
  onSuccess?: UploadProps['onSuccess'];
  onError?: UploadProps['onError'];
  drag?: boolean;
  disabled?: boolean;
  fileSize?: number;
  fileType?: string[];
  height?: string;
  width?: string;
  borderRadius?: string;
  iconSize?: number;
  dir?: string;
}, { clear: () => void }, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:imageUrl': (value: string) => void;
  'update:modelValue': (value: string) => void;
  change: (file?: File) => void;
}>;

export default AuraUploadImg;
```

API 资料来自 `docs/component/upload-img.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
