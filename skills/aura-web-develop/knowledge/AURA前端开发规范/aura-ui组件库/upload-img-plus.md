# AuraUploadImgPlus 多图上传

公共子入口 `@fxft/aura-ui/upload-img-plus`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

上传多张图片，支持预览、删除和拖拽排序。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraUploadImgPlus from '@fxft/aura-ui/upload-img-plus';
import { ref } from 'vue';

const value = ref('');
// 默认真实请求同源 /admin/sys-file/upload；接口及认证配置见公共接入。
</script>

<template>
  <AuraUploadImgPlus v-model="value" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 图片地址列表 | `string \| Record<string, any> \| (string \| Record<string, any>)[]` | `''` | 否 |
| imageUrl | 图片地址（向下兼容） | `string` | `''` | 否 |
| action | 上传接口地址；未提供 httpRequest 时空字符串会阻止上传 | `string` | `'/admin/sys-file/upload'` | 否 |
| data | 上传携带的参数 | `Record<string, any>` | `{}` | 否 |
| limit | 图片数量限制 | `number` | `5` | 否 |
| fileSize | 大小限制(MB) | `number` | `5` | 否 |
| fileType | 文件类型 | `string[]` | `['png', 'jpg', 'jpeg']` | 否 |
| isShowTip | 是否显示提示 | `boolean` | `true` | 否 |
| drag | 是否拖动排序 | `boolean` | `true` | 否 |
| disabled | 是否禁用 | `boolean` | `false` | 否 |
| baseURL | 覆盖应用基础地址 | `string` | `undefined` | 否 |
| headers | 整体覆盖应用请求头 | `Record<string, string>` | `undefined` | 否 |
| httpRequest | 自定义上传请求 | `UploadProps['httpRequest']` | `undefined` | 否 |
| beforeUpload | 自定义上传前校验，替代默认校验；支持异步校验 | `UploadProps['beforeUpload']` | `undefined` | 否 |
| onSuccess | (response, file) => void；内置成功处理完成后调用 | `(response: any, file: UploadFile) => void` | `undefined` | 否 |
| onError | (error, file) => void；内置错误处理完成后调用 | `(error: Error, file: UploadFile) => void` | `undefined` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:modelValue | 批量成功合并、删除或拖拽排序时先触发 | value: string |
| update:imageUrl | 紧随 update:modelValue；无 change 事件，onSuccess/onError 是 Props 回调 | value: string |

## v-model

`v-model` 或 `v-model:imageUrl` 输入逗号字符串或文件数组，输出均为字符串；非空 `modelValue` 优先。

## 注意事项

- 默认请求 /admin/sys-file/upload；可传入 httpRequest 或通过公共 upload 配置基础地址与认证头。仅数字 code===200 视为成功，地址按 baseURL + response.data.url 拼接。
- 输入使用逗号字符串或文件数组，输出两个模型均为逗号字符串；单个对象不支持回显。
- 文件必须严格小于 fileSize，类型按 MIME/扩展名包含匹配；自定义 beforeUpload 会替代默认校验。
- 成功、失败、校验拒绝或取消都结束当前文件处理；批次结束后回传成功文件。httpRequest 支持回调或 Promise，并接收发送时的请求头。
- disabled 不会禁用拖拽排序；已有回显值不会自动补上应用基础地址。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';
import type { UploadFile, UploadProps } from 'element-plus';

declare const AuraUploadImgPlus: DefineComponent<{
  modelValue?: string | Record<string, any> | (string | Record<string, any>)[];
  imageUrl?: string;
  action?: string;
  data?: Record<string, any>;
  limit?: number;
  fileSize?: number;
  fileType?: string[];
  isShowTip?: boolean;
  drag?: boolean;
  disabled?: boolean;
  baseURL?: string;
  headers?: Record<string, string>;
  httpRequest?: UploadProps['httpRequest'];
  beforeUpload?: UploadProps['beforeUpload'];
  onSuccess?: (response: any, file: UploadFile) => void;
  onError?: (error: Error, file: UploadFile) => void;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: string) => void;
  'update:imageUrl': (value: string) => void;
}>;

export default AuraUploadImgPlus;
```

API 资料来自 `docs/component/upload-img-plus.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
