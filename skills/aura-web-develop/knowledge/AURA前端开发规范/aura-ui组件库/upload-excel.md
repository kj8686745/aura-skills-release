# AuraUploadExcel Excel 导入

公共子入口 `@fxft/aura-ui/upload-excel`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

通过业务接口导入 Excel，支持模板下载和导入错误明细。

支持通过 `accept` 选择其他文件格式。例如菜单导入可使用 `<AuraUploadExcel accept=".xlsx,.xls,.json" />`，同时传入业务 `url`。组件按文件上传，不解析或转换 JSON；接口需支持相应格式。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraUploadExcel from '@fxft/aura-ui/upload-excel';
import { ref } from 'vue';
import type UploadExcel from '@fxft/aura-ui/upload-excel';

const dialog = ref<InstanceType<typeof UploadExcel>>();
// 将占位路径替换为真实业务导入接口，并配置所需认证信息。
</script>

<template>
  <button @click="dialog?.show()">打开导入</button>
  <AuraUploadExcel ref="dialog" title="Excel 导入" url="/REPLACE_WITH_IMPORT_ENDPOINT" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| url | 业务导入接口地址，未配置时无法提交 | `string` | `undefined` | 提交时必填 |
| title | 对话框标题 | `string` | `undefined` | 否 |
| tempUrl | 模板标识、以 `/` 开头的路径或 HTTP(S) 地址 | `string` | `undefined` | 否 |
| accept | 文件选择类型，透传给 Element Plus Upload；格式提示同步更新，空字符串不限制选择类型 | `string` | `.xlsx, .xls` | 否 |
| baseURL | 覆盖应用基础地址；可传空字符串 | `string` | `undefined` | 否 |
| headers | 整体覆盖应用请求头 | `Record<string, string>` | `undefined` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| sizeChange | 当前不会触发 | 无 |
| refreshDataList | change 后，业务成功或非成功且 data 为非空错误数组时触发 | 无 |
| change | 传输成功回调先清空文件，再发送原响应和回调 fileList；此时业务 code 未判断，files 可能已被 clearFiles 清空 | response: any, files: any[] |

## Methods

| 方法名 | 说明 | 参数 | 返回值 |
| --- | --- | --- | --- |
| show | 清空上轮状态、文件、错误页，打开弹窗；submit 未公开 | 无 | void |

## 注意事项

- 必须传入业务导入 url，未配置时阻止提交。请求使用 Element Plus 原生上传，通过公共 upload 配置接入基础地址、认证头和路径适配。
- code 为 0、字符串 "0"、200，或 success=true 时成功；失败响应的 data 为非空数组时显示错误表格，每页 20 条。
- 模板下载需提供 upload.downBlobFile。模板标识按 /admin/sys-file/import/template/<标识> 下载，完整地址直接下载，文件名 temp.xlsx。
- show 会重置文件和错误分页。sizeChange 事件当前不会触发；文件格式与导入内容仍由服务端校验。


## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraUploadExcel: DefineComponent<{
  url?: string;
  title?: string;
  tempUrl?: string;
  accept?: string;
  baseURL?: string;
  headers?: Record<string, string>;
}, { show: () => void }, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  sizeChange: () => void;
  refreshDataList: () => void;
  change: (response: any, files: any[]) => void;
}>;

export default AuraUploadExcel;
```

API 资料来自 `docs/component/upload-excel.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
