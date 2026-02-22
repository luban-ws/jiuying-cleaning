# CleanSpace 图标

- `icon.svg` 为应用图标矢量源文件，几何原创设计，无第三方图案或版权问题。
- 需生成 **1024×1024** PNG 并放入 `CleanSpace/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`。

## 生成 1024 PNG

**方式一（推荐）：** 使用 macOS 自带的 `qlmanage` 或设计工具导出  
- 用 Safari 打开 `icon.svg`，截图或另存为 PNG（需调整为 1024×1024），或  
- 用 Figma/Sketch/Inkscape 打开 SVG，导出 1024×1024 PNG。

**方式二：** 命令行（需安装 rsvg-convert）  
```bash
brew install librsvg
rsvg-convert -w 1024 -h 1024 -o ../CleanSpace/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png icon.svg
```

**方式三：** 在 Xcode 中打开项目后，将 `AppIcon-1024.png` 拖入 `AppIcon.appiconset`。

若未放置 PNG，Xcode 会使用默认占位图标，应用仍可正常编译运行。
