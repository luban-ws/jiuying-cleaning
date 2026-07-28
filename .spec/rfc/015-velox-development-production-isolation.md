# RFC 015：Velox Development / Production 应用隔离

**状态**：实施中
**创建日期**：2026-07-27
**最后更新**：2026-07-27
**作者**：CleanSpace
**依赖**：[RFC 013](./013-velox-ui-shell-migration.md)、[RFC 014](./014-single-instance-desktop-lifecycle.md)

---

## 摘要

CleanSpace 必须同时提供两个可并行运行、各自单实例的 macOS 应用身份：

| Variant | App bundle | Bundle identifier |
|---------|------------|-------------------|
| Production | `Cleaning.app` | `me.systembug.cleaning` |
| Development | `Cleaning Dev.app` | `me.systembug.cleaning.dev` |

pnpm 继续调用官方 Velox CLI。不得新增 `.sh`，不得在构建期间覆盖 canonical `velox.json`。

## 问题

当前 Debug 与 Release 都读取根 `velox.json`，因此都输出 `Cleaning.app` 和 `me.systembug.cleaning`。两者不仅无法在 Finder / Dock 中稳定区分，RFC 014 的单实例锁也会把 Development 与 Production 放进同一互斥域。

这是真实身份冲突，不是显示名问题。仅重命名目录不能改变 Launch Services、`Bundle.main.bundleIdentifier`、单实例锁或应用数据域。

## 目标

1. Velox 官方 Bundler 生成两个明确 app 名称与 bundle identifier。
2. Development 与 Production 可同时运行。
3. 同一 variant 重复启动仍只保留一个实例。
4. 根 `velox.json` 始终代表 Production，构建过程不得交换或覆写它。
5. `pnpm dev`、Debug bundle、Release bundle 都通过官方 Velox CLI。
6. 不新增 `.sh`；上游缺口仅允许窄 JavaScript 适配。

## 非目标

- 不重命名内部 Swift target / executable `CleanSpaceDesktop`。
- 不复制 Swift package 或业务源码。
- 不修改发布签名与 notarization 策略。
- 不为两个 variant 建立不同业务功能。

## 方案比较

### 方案 A：构建后复制并篡改 Production bundle

先生成 `Cleaning.app`，再复制为 `Cleaning Dev.app`，修改 `Info.plist` 与签名。

优点：代码少。

缺点：Velox 从未见过 Development 身份；bundle 名称、资源 config、运行时 config 与签名容易分裂。拒绝。

### 方案 B：独立 Development config 驱动官方 Velox CLI

Node profile runner 从 canonical `velox.json` 派生 Development config，写入 `.build/velox-profile/development/velox.json`，从该目录执行官方 Velox CLI。Velox CLI 向上找到同一个 `Package.swift`，并用 Development config 生成正确 `.app` 名称、identifier 与窗口标题。

当前 Velox Bundler 会错误复制包根 `velox.json`，而非本次实际加载的 config。runner 只在 bundle 完成后把已加载的 Development config 写入 `Contents/Resources/velox.json`，然后做最终 ad-hoc 签名。

优点：身份在 Velox 构建前已经确定；不复制 package；不交换 canonical config；适配边界窄且可删除。

缺点：需要保留一个有明确上游删除条件的 JavaScript 适配。

## 决策

采用方案 B。

## 技术设计

### 1. Canonical 与派生配置

根 `desktop-velox/velox.json` 只表示 Production。Development profile 纯函数只覆盖：

- `productName` → `Cleaning Dev`
- `identifier` → `me.systembug.cleaning.dev`
- 主窗口 `title` → `Cleaning Dev`
- hook 相对工作目录，使其从 profile 目录仍回到 `apps/desktop`

其他配置从 canonical config 派生，避免双份配置漂移。

### 2. CLI 所有权

pnpm 调用链必须进入官方 Velox CLI：

```text
pnpm dev
  → Node profile runner
  → velox dev

pnpm build:app:dev
  → Node profile runner
  → velox build --debug --bundle

pnpm build:app
  → velox build --bundle
```

Node 不实现 Swift build、Velox bundling、Vite dev watcher 或 bundle 目录结构。

### 3. Bundle config 真实性

Velox 修复“复制实际加载 config”后，应删除 bundle config 覆盖步骤。当前适配只允许：

1. 确认 `Cleaning Dev.app` 已由 Velox 生成。
2. 用本次派生 config 覆盖 bundle 内错误的 Production `velox.json`。
3. 对完成后的 app 做最终 ad-hoc 签名。

不得复制或重命名 `Cleaning.app` 来制造 Development。

### 4. Info.plist 所有权

`Support/Info.plist` 不得硬编码：

- `CFBundleDisplayName`
- `CFBundleName`
- `CFBundleIdentifier`

这些键由 Velox 的 `productName` 与 `identifier` 生成。自定义 plist 只保留 Velox 未覆盖的项目元数据。

### 5. 运行时 config

`DesktopApp` 使用 `VeloxConfig.load()`：

- bare `velox dev` 从 profile runner 当前目录读取 Development config；
- `.app` 从 `Bundle.main.resourcePath` 读取自身 config。

不得用编译期 `#filePath` 回到源码目录。已安装 app 不能依赖开发机源码路径。

### 6. 单实例域

app bundle 使用 `Bundle.main.bundleIdentifier`。bare `velox dev` 没有 bundle identifier 时，profile runner 注入 `CLEANING_BUNDLE_IDENTIFIER=me.systembug.cleaning.dev`。最终 fallback 才是 Production identifier。

解析优先级：

1. `Bundle.main.bundleIdentifier`
2. `CLEANING_BUNDLE_IDENTIFIER`
3. `me.systembug.cleaning`

## 测试策略

1. Node 纯函数测试：Development config 名称、identifier、窗口 title 与 hook 工作目录。
2. Swift 单测：bundle identifier 优先、Development 环境 fallback、Production 最终 fallback。
3. 契约检查：两个 `.app` 的 `Info.plist`、Resources config、icon、dylib load path 与签名。
4. 手动验收：同时打开两个 app；确认两个进程共存；再次打开各自 app 时只唤醒同 variant。

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| profile 配置漂移 | 每次从 canonical config 纯函数派生 |
| 两个构建并发覆盖 | profile config 写独立 `.build/velox-profile/development` |
| Velox Bundler 复制错误 config | bundle 后窄覆盖；上游修复后删除 |
| custom plist 覆盖身份 | 删除三个硬编码身份键 |
| bare dev 与 Production 抢同一锁 | 显式 Development identifier 环境变量 |
| 修改 Mach-O 后签名失效 | bundle 完成后最终签名并严格验证 |

## 实施任务

1. `TASK-015-01`：Development profile config 派生与 Node 单测。
2. `TASK-015-02`：pnpm → Velox CLI 命令与 bundle config 修正。
3. `TASK-015-03`：运行时 config 加载与单实例身份解析。
4. `TASK-015-04`：双 bundle 构建、签名、并行运行与同 variant 单实例验收。

## 验收标准

1. Debug 输出 `Cleaning Dev.app` / `me.systembug.cleaning.dev`。
2. Release 输出 `Cleaning.app` / `me.systembug.cleaning`。
3. 两个 bundle 的 Resources config 与 `Info.plist` 身份一致。
4. 两个 app 可同时运行。
5. 每个 variant 各自保持单实例。
6. `otool -L` 无开发机绝对 dylib 路径。
7. `codesign --verify --deep --strict` 通过。
8. Node、Swift、pnpm 相关测试通过。

## 回滚

删除 profile runner与相关 pnpm 命令，恢复 `DesktopApp` 的 Production fallback。Production canonical config 与 `Cleaning.app` 不迁移、不改名。

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-27 | 用户批准 Development / Production 独立 app 名称、bundle identifier 与并行运行 |
