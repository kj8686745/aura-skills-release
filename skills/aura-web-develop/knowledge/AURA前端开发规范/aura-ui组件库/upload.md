# AuraUpload 文件上传

公共子入口 `@fxft/aura-ui/upload`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

上传附件并展示文件列表，支持删除、下载和手动提交。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraUpload from '@fxft/aura-ui/upload';
import { ref } from 'vue';

const value = ref('');
// 默认真实请求同源 /admin/sys-file/upload；接口及认证配置见公共接入。
</script>

<template>
  <AuraUpload v-model="value" :limit="1" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 上传文件的地址列表 | `string \| (string \| Record<string, any>)[]` | `undefined` | 否 |
| limit | 上传文件数量限制 | `number` | `5` | 否 |
| fileSize | 上传文件大小限制(MB) | `number` | `5` | 否 |
| minFileSize | 最小文件大小(KB)，0 为不限制 | `number` | `0` | 否 |
| fileType | 上传文件类型限制 | `string[]` | `['png', 'jpg', 'jpeg', 'doc', 'xls', 'ppt', 'txt', 'pdf', 'docx', 'xlsx', 'pptx']` | 否 |
| isShowTip | 是否显示提示信息 | `boolean` | `true` | 否 |
| uploadFileUrl | 上传接口地址；传入空字符串时拒绝上传 | `string` | `'/admin/sys-file/upload'` | 否 |
| type | 上传组件类型 | `'default' \| 'simple'` | `'default'` | 否 |
| data | 上传时附带的额外参数 | `Record<string, any>` | `{}` | 否 |
| dir | 文件上传目录 | `string` | `''` | 否 |
| autoUpload | 是否自动上传 | `boolean` | `true` | 否 |
| disabled | 是否禁用 | `boolean` | `false` | 否 |
| baseUrl | 基础URL，未指定则使用应用上传配置 | `string` | `undefined` | 否 |
| headers | 请求头，未指定则使用应用 getHeaders | `Record<string, string>` | `undefined` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:modelValue | 批量成功合并或删除时先发 | value: string |
| change | 紧随 update:modelValue，files 保留 fileUrl 等元数据 | value: string, files: Record<string, any>[] |

## Methods

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| submit | 调用内部 ElUpload.submit；用于 autoUpload=false，disabled 无上传实例时无操作 | 无 | void |

## v-model

`v-model` 输入 URL 字符串或字符串/文件对象数组，输出为逗号连接的 URL 字符串；清空输出 `''`。

## 注意事项

- 默认接口为 /admin/sys-file/upload。请求地址为 baseUrl + adaptationUrl(uploadFileUrl)，baseUrl 可为空；显式 headers 整体覆盖公共认证头。
- code 为 0、字符串 "0"、200，或 success=true 时成功；从 data.url/data.fileName 读取地址。change 的 files 包含 name、url、fileUrl、fileSize、fileName、fileType。
- 成功、失败、校验拒绝或取消均结束对应文件处理，批次结束后合并成功文件；组件不自动重试。请求头在发送时读取。
- fileSize 要求严格小于上限，minFileSize 允许等于下限，后缀匹配区分大小写。文件名中的逗号或查询特殊字符可能影响请求地址。
- 下载或只读列表预览需提供 upload.downBlobFile；没有下载服务时不能完成下载。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraUpload: DefineComponent<{
  modelValue?: string | (string | Record<string, any>)[];
  limit?: number;
  fileSize?: number;
  minFileSize?: number;
  fileType?: string[];
  isShowTip?: boolean;
  uploadFileUrl?: string;
  type?: 'default' | 'simple';
  data?: Record<string, any>;
  dir?: string;
  autoUpload?: boolean;
  disabled?: boolean;
  baseUrl?: string;
  headers?: Record<string, string>;
}, { submit: () => void }, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: string) => void;
  change: (value: string, files: Record<string, any>[]) => void;
}>;

export default AuraUpload;
```

API 资料来自 `docs/component/upload.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
