# AuraImagePaste 图片粘贴上传

公共子入口 `@fxft/aura-ui/image-paste`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

支持点击、拖拽和粘贴上传图片。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraImagePaste from '@fxft/aura-ui/image-paste';
import { ref } from 'vue';

const value = ref('');
const headers = {}; // 生产按公共接入配置动态认证头。
</script>

<template>
  <AuraImagePaste v-model="value" action="/REPLACE_WITH_UPLOAD_ENDPOINT" :headers="headers" />
</template>
```

## Attributes

| 属性 | 说明 | 默认值 | 类型 | 必填 |
| --- | --- | --- | --- | --- |
| modelValue | 逗号 URL 字符串或字符串/文件对象数组；单对象不推荐 | `''` | `string \| Record<string, any> \| (string \| Record<string, any>)[]` | 否 |
| action | 与基础地址直接拼接的上传路径 | `'/admin/sys-file/upload'` | `string` | 否 |
| data | multipart 附加字段 | `{}` | `Record<string, any>` | 否 |
| limit | 图片数量上限 | `5` | `number` | 否 |
| fileSize | 大小上限 MB；点击严格 <，粘贴 <= | `2` | `number` | 否 |
| fileType | MIME/扩展名包含匹配列表 | `['png', 'jpg', 'jpeg']` | `string[]` | 否 |
| isShowTip | 显示提示 | `true` | `boolean` | 否 |
| disabled | 禁止点击上传与全局粘贴处理 | `false` | `boolean` | 否 |
| baseURL | 覆盖 upload.baseUrl，未配置时为空串 | `undefined` | `string` | 否 |
| headers | 整体替换 upload.getHeaders() 结果 | `undefined` | `Record<string, string>` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:modelValue | 点击上传批量合并、粘贴成功或删除时触发 | value: string |

## v-model

`v-model` 可传入逗号字符串或字符串/文件对象数组，输出为逗号分隔的原始 URL 字符串。

## 注意事项

- 点击和拖拽使用 Element Plus 原生上传；粘贴优先调用公共 upload.postFile，否则使用 fetch。postFile 应返回 axios 格式 { data: 业务响应 }。
- 业务响应 code 为数字 0/200 或 success=true 时成功。回显相对地址会拼接基础地址，模型输出原始 URL。
- 一次粘贴只处理第一张图片；多个可见实例会同时响应全局粘贴，页面中应控制可粘贴实例数量。
- 点击上传要求文件严格小于 fileSize，粘贴允许等于上限。请求头在每次发送时读取。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraImagePaste: DefineComponent<{
  modelValue?: string | Record<string, any> | (string | Record<string, any>)[];
  action?: string;
  data?: Record<string, any>;
  limit?: number;
  fileSize?: number;
  fileType?: string[];
  isShowTip?: boolean;
  disabled?: boolean;
  baseURL?: string;
  headers?: Record<string, string>;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:modelValue': (value: string) => void;
}>;

export default AuraImagePaste;
```

API 资料来自 `docs/component/image-paste.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
