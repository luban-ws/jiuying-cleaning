# CleanSpace 图标

- **`icon.svg`**：应用图标矢量源（几何原创，无第三方图案）。
- **`AppIcon-1024.png`**：由构建流程自动生成，**无需手动导出**。

## 自动生成（默认）

Xcode 构建目标 **CleanSpace** 时，会先执行 **Run Script**「Generate App Icon from SVG」，调用本目录下的 `generate-app-icon.sh`：

- 若存在 `rsvg-convert`（例如 `brew install librsvg`），会从 `icon.svg` 写出 `../CleanSpace/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`。
- 若没有 `rsvg-convert`，则使用仓库里已提交的 `AppIcon-1024.png`，构建照常通过。

也可在终端手动同步（在仓库 `app/design` 目录下执行）：

```bash
./generate-app-icon.sh
```
