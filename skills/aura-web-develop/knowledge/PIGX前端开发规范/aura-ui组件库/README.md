# aura-ui 组件接入契约

本目录统一维护 `@fxft/aura-ui` 的当前组件资料，覆盖全部 **39 个公开组件**，包含内联基础示例、Props、事件、插槽、公开方法、数据结构和公开类型声明。

## 使用方式

1. 先读 [能力清单与公共接入](../aura-ui能力清单与接入规范.md)，确认项目的组件导入、样式、语言和服务绑定方案。
2. 按下表读取本次使用的组件页，核对模型、必传属性、事件载荷、公开 ref 方法及接口数据结构。
3. 结合项目实际安装包确认能力。按需绑定项目 request、消息、上传认证、文件地址、租户或权限上下文。
4. 示例中的演示数据、页面路径和中文文案按项目真实接口、字典和 i18n 替换，样式放在项目已有样式边界。
5. 按用户授权完成项目检查和运行验证，交付时说明实际完成与待验证范围。

## 组件索引

| 组件 | 公开子入口（省略 @fxft/aura-ui/） | 详细契约 |
| --- | --- | --- |
| `AuraTip` | `tip` | [tip](tip.md) |
| `AuraDelWrap` | `del-wrap` | [del-wrap](del-wrap.md) |
| `AuraTagList` | `tag-list` | [tag-list](tag-list.md) |
| `AuraNameAvatar` | `name-avatar` | [name-avatar](name-avatar.md) |
| `AuraShortcutCard` | `shortcut-card` | [shortcut-card](shortcut-card.md) |
| `AuraNoticeBar` | `notice-bar` | [notice-bar](notice-bar.md) |
| `AuraSvgIcon` | `svg-icon` | [svg-icon](svg-icon.md) |
| `AuraImagePreview` | `image-preview` | [image-preview](image-preview.md) |
| `AuraPopup` | `popup` | [popup](popup.md) |
| `AuraPopoverInput` | `popover-input` | [popover-input](popover-input.md) |
| `AuraColorPicker` | `color-picker` | [color-picker](color-picker.md) |
| `AuraTreeSelect` | `tree-select` | [tree-select](tree-select.md) |
| `AuraSign` | `sign` | [sign](sign.md) |
| `AuraCrontab` | `crontab` | [crontab](crontab.md) |
| `AuraStrengthMeter` | `strength-meter` | [strength-meter](strength-meter.md) |
| `AuraFormTable` | `form-table` | [form-table](form-table.md) |
| `AuraDictTag` | `dict-tag` | [dict-tag](dict-tag.md) |
| `AuraDictText` | `dict-text` | [dict-text](dict-text.md) |
| `AuraDictSelect` | `dict-select` | [dict-select](dict-select.md) |
| `AuraPagination` | `pagination` | [pagination](pagination.md) |
| `AuraRightToolbar` | `right-toolbar` | [right-toolbar](right-toolbar.md) |
| `AuraQueryTree` | `query-tree` | [query-tree](query-tree.md) |
| `AuraChinaArea` | `china-area` | [china-area](china-area.md) |
| `AuraOrgTreeView` | `org-tree-view` | [org-tree-view](org-tree-view.md) |
| `AuraOrgSelector` | `org-selector` | [orgSelector](orgSelector.md) |
| `AuraUpload` | `upload` | [upload](upload.md) |
| `AuraUploadExcel` | `upload-excel` | [upload-excel](upload-excel.md) |
| `AuraUploadImg` | `upload-img` | [upload-img](upload-img.md) |
| `AuraUploadImgPlus` | `upload-img-plus` | [upload-img-plus](upload-img-plus.md) |
| `AuraImagePaste` | `image-paste` | [image-paste](image-paste.md) |
| `AuraCodeEditor` | `code-editor` | [code-editor](code-editor.md) |
| `AuraEditor` | `editor` | [editor](editor.md) |
| `AuraMdRenderer` | `md-renderer` | [md-renderer](md-renderer.md) |
| `AuraVideoPlayer` | `video-player` | [video-player](video-player.md) |
| `AuraSafeSandboxIframe` | `safe-sandbox-iframe` | [safe-sandbox-iframe](safe-sandbox-iframe.md) |
| `AuraMindMap` | `mind-map` | [mind-map](mind-map.md) |
| `AuraLinkPicker` | `link-picker` | [link](link.md) |
| `AuraIconSelector` | `icon-selector` | [icon-selector](icon-selector.md) |
| `AuraBusinessIconPicker` | `business-icon-picker` | [business-icon-picker](business-icon-picker.md) |

## 资料依据

组件说明依据本地 SDK 的组件 API 文档、公开声明和运行实现整理。技能保留内联示例与按需阅读入口，接入时核对项目实际安装包的公开能力。
