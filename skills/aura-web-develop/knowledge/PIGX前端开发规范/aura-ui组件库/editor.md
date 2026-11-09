# AuraEditor 富文本编辑器

公共子入口 `@fxft/aura-ui/editor`。

[公共接入规范](../aura-ui能力清单与接入规范.md) · [组件索引](README.md)

基于 wangEditor Next 的富文本编辑器，可输出 HTML 和纯文本。

接入方式见[快速开始](../aura-ui能力清单与接入规范.md#按需解析)。

## 使用示例

```vue
<script setup lang="ts">
import AuraEditor from '@fxft/aura-ui/editor';
import { ref } from 'vue';

const html = ref('');
const text = ref('');
</script>

<template>
  <AuraEditor v-model:getHtml="html" v-model:getText="text" :height="310" />
</template>
```

## Attributes

| 属性 | 说明 | 类型 | 默认值 | 必填 |
| --- | --- | --- | --- | --- |
| disable | 初始化时是否禁用编辑器 | `boolean` | `false` | 否 |
| placeholder | 初始化内容框占位符 | `string` | `'请输入内容...'` | 否 |
| mode | 初始化模式，可选 default / simple | `string` | `'default'` | 否 |
| height | 编辑器高度，数字或数字字符串补 px，也支持 CSS 尺寸 | `string \| number` | `'310'` | 否 |
| width | 编辑器宽度，尺寸处理与 height 相同 | `string \| number` | `'auto'` | 否 |
| getHtml | 双向绑定，用于获取 editor.getHtml() | `string` | `undefined` | 否 |
| getText | 接收编辑器输出的纯文本；外部赋值不会回写编辑器 | `string` | `undefined` | 否 |
| uploadFileUrl | 上传接口路径，默认由布局 request 服务处理 | `string` | `'/admin/sys-file/upload'` | 否 |
| uploadFieldName | multipart 文件字段名 | `string` | `'file'` | 否 |
| uploadMaxFileSize | 单文件大小上限，字节 | `number` | `10 * 1024 * 1024` | 否 |
| uploadRequest | 自定义上传函数，优先于布局 request 和原生上传配置 | `(file: File) => string \| { url?: string } \| void \| Promise<string \| { url?: string } \| void>` | `null` | 否 |

## Events

| 事件名 | 说明 | 参数 |
| --- | --- | --- |
| update:getHtml | onChange 先发 HTML；卸载有实例时先输出空串 | html: string |
| update:getText | 紧随 update:getHtml；getText 是输出属性，不反向设置内容 | text: string |

## v-model

`v-model:getHtml` 绑定 HTML 字符串；`v-model:getText` 接收纯文本输出，外部赋值不会回填。

## 注意事项

- 上传优先使用 uploadRequest(file)，返回 URL 字符串、{ url } 或对应 Promise。图片和视频共用该回调，空结果不插入内容。
- 布局提供 request 时，默认上传通过该服务 POST multipart，字段名为 uploadFieldName，显式使用 Enc-Flag: false，并在每次发送时读取 upload.getHeaders。request 返回契约为 { data: { url } }，URL 优先通过布局 getFileUrl 处理。未配置 getFileUrl 时保留完整地址，只给尚无前缀的相对地址补充 upload.baseUrl。
- 仅提供 upload 配置的旧用法继续走原生上传，接口为 baseUrl + uploadFileUrl，认证头按编辑器初始化值生效。缺少上传回调、request 和 upload 配置时不会发送请求。
- placeholder、mode 和 disable 按初始化值生效。图片和视频共享上述上传配置。
- 外部 getHtml 更新会回填内容，getText 只接收输出。卸载时两个模型会输出空字符串，业务保存逻辑需避开卸载清空。
- 依赖浏览器 DOM。应用直接使用其他编辑器实例时，其 Boot 插件不会自动注册到本组件。



## 公开类型声明

以下摘自当前 SDK 的公开入口声明，供核对 Props、事件与实例类型。业务代码通过公开子入口导入组件或类型，运行行为按本页说明与项目安装包核对。

```ts
import type { ComponentOptionsMixin, DefineComponent } from 'vue';

declare const AuraEditor: DefineComponent<{
  disable?: boolean;
  placeholder?: string;
  mode?: string;
  height?: string | number;
  width?: string | number;
  getHtml?: string;
  getText?: string;
  uploadFileUrl?: string;
  uploadFieldName?: string;
  uploadMaxFileSize?: number;
  uploadRequest?: (file: File) => string | { url?: string } | void | Promise<string | { url?: string } | void>;
}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, {
  'update:getHtml': (html: string) => void;
  'update:getText': (text: string) => void;
}>;

export default AuraEditor;
```

API 资料来自 `docs/component/editor.md`，声明来自 SDK 的公开组件入口。演示数据和中文文案在业务中替换为真实接口、字典和项目 i18n，样式、请求、权限及资源按公共接入规范绑定。
