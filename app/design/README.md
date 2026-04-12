# CleanSpace 图标

- **`icon.svg`**：应用图标矢量源（几何原创，无第三方图案）。
- **`AppIcon-1024.png`**：由 `generate-app-icon.sh` 生成，路径为 `Sources/CleanSpaceKit/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`。

## 自动生成

在 **`npm run build:app`**、`npm run bundle:app` 或手动执行脚本时会调用 `generate-app-icon.sh`：

- 若存在 `rsvg-convert`（例如 `brew install librsvg`），会从 `icon.svg` 写出上述 PNG。
- 若没有 `rsvg-convert`，则使用仓库里已提交的 `AppIcon-1024.png`，构建照常通过。

在仓库 `app/design` 目录下手动同步：

```bash
./generate-app-icon.sh
```
