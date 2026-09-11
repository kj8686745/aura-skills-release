# 安装与接入

新版 API 要求 `@fxft/ui-plus >= 1.1.2`。缺失或版本不足时先说明会修改 `package.json` 与 lock 文件，获得授权后才使用项目现有包管理器安装。

私有 registry 仅用于安装命令：

```text
https://repository.fxft.online/repository/npm-public/
```

## 按需引入

```ts
import Components from 'unplugin-vue-components/vite'
import AutoImport from 'unplugin-auto-import/vite'
import FxftUiPlusResolver from '@fxft/ui-plus/resolver'

export default defineConfig({
  plugins: [
    AutoImport({ resolvers: [FxftUiPlusResolver()] }),
    Components({ resolvers: [FxftUiPlusResolver()] }),
  ],
})
```

已有 Resolver 时只追加，不覆盖其它插件。已有全量注册时沿用：

```ts
import FxftUiPlus from '@fxft/ui-plus'
import '@fxft/ui-plus/dist/index.css'

app.use(FxftUiPlus)
```

新版 Web 视频组件不要求业务提供 Jessibuca 脚本或 decoder。不要为它们新增旧播放器资源。
