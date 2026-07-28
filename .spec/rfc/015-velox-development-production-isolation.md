# RFC 015：Velox Development / Production 应用隔离

**状态**：实施中
**创建日期**：2026-07-27
**最后更新**：2026-07-28
**作者**：CleanSpace
**依赖**：[RFC 013](./013-velox-ui-shell-migration.md)、[RFC 014](./014-single-instance-desktop-lifecycle.md)

---

## 摘要

CleanSpace 必须同时提供两个可并行运行、各自单实例的 macOS 应用身份：

| Variant | App bundle | Bundle identifier |
|---------|------------|-------------------|
| Production | `Cleaning.app` | `me.systembug.cleaning` |
| Development | `Cleaning Dev.app` | `me.systembug.cleaning.dev` |

`pnpm dev` 必须直接调用 Velox CLI，并由 Velox 在 macOS 上构建、签名和启动
`Cleaning Dev.app`。不得启动 SwiftPM 裸 executable，不得新增 `.sh`，不得在构建期间覆盖
canonical `velox.json`。

## 问题

当前 Velox `DevCommand` 通过 `swift run` 启动
`.build/debug/CleanSpaceDesktop`，frontend-only restart 则直接启动同一裸 executable。该进程不在
`.app/Contents/MacOS` 内，因此没有可信的 `Info.plist`、bundle identifier、`CFBundleIconFile`
和 Bundle Resources 生命周期。运行时设置 `NSApplication.applicationIconImage` 的单测虽能通过，
真实 Dock 仍显示 generic executable 图标。

Debug bundle 与 Release 读取同一根 `velox.json` 时还会输出相同的 `Cleaning.app` 和
`me.systembug.cleaning`。两者不仅无法在 Finder / Dock 中稳定区分，RFC 014 的单实例锁也会把
Development 与 Production 放进同一互斥域。

这是真实身份冲突，不是显示名问题。仅重命名目录不能改变 Launch Services、`Bundle.main.bundleIdentifier`、单实例锁或应用数据域。

## 目标

1. `velox dev` 在 macOS 上生成并启动真正的 `Cleaning Dev.app`。
2. Velox 官方 Bundler 生成两个明确 app 名称与 bundle identifier。
3. Development 与 Production 可同时运行。
4. 同一 variant 重复启动仍只保留一个实例。
5. 根 `velox.json` 始终代表 Production，构建过程不得交换或覆写它。
6. `pnpm dev`、Debug bundle、Release bundle 都通过官方 Velox CLI。
7. 不新增 `.sh`；上游缺口仅允许窄 JavaScript 适配。

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

### 方案 B：Velox CLI 直接开发，独立 Development config 打包

`pnpm dev` 直接执行官方 `velox dev`，不允许 Node runner 持有开发进程。Debug bundle 才由 Node profile runner 从 canonical `velox.json` 派生 Development config，写入 `.build/velox-profile/development/velox.json`，再执行官方 Velox CLI。Velox CLI 向上找到同一个 `Package.swift`，并用 Development config 生成正确 `.app` 名称、identifier 与窗口标题。

当前 Velox Bundler 会错误复制包根 `velox.json`，而非本次实际加载的 config。runner 只在 bundle 完成后把已加载的 Development config 写入 `Contents/Resources/velox.json`，然后做最终 ad-hoc 签名。

优点：Velox 完整拥有开发生命周期；bundle 身份在 Velox 构建前已经确定；不复制 package；不交换 canonical config；适配边界窄且可删除。

缺点：需要保留一个有明确上游删除条件的 JavaScript 适配。

### 方案 C：在 `luban-ws/velox` 实现 macOS bundle-first dev

Velox 配置提供 Development identity override。`DevCommand` 不再在 macOS 上调用 `swift run`；
它先执行 `swift build`，再复用 `VeloxBundler` 生成和 ad-hoc 签名 `.app`，最后启动
`Contents/MacOS/<target>`。Swift 变化触发 build、bundle、sign、relaunch；外部 Vite dev server
继续负责 React HMR。

Velox Bundler 必须把本次传入的 effective config 序列化到 Bundle Resources，不得从
`packageDirectory/velox.json` 重新读取另一个配置。Cleaning 的 SwiftPM dependency 固定到
`https://github.com/luban-ws/velox` 的已验证 revision。

优点：图标、bundle identifier、资源、单实例与 dylib 都服从真实 macOS Bundle 生命周期；
`pnpm dev` 仍直达官方 Velox CLI；Cleaning 不复制框架生命周期。

缺点：需要维护并验证 Velox fork；上游合并前需固定 revision，避免 branch 漂移。

## 决策

采用方案 C。方案 B 只保留为迁移期间 Debug bundle 配置适配；Velox fork 支持 effective
Development config 后删除该适配。

## 技术设计

### 1. Velox Development identity

根 `desktop-velox/velox.json` 的基础身份只表示 Production，并通过 Velox 原生
`development` override 声明：

- `productName` → `Cleaning Dev`
- `identifier` → `me.systembug.cleaning.dev`

Velox `DevCommand` 加载配置后生成一次 effective Development config。Bundler、Bundle 内
`velox.json`、Info.plist 和运行进程必须共享同一值，禁止重新读取另一个配置源。

### 2. CLI 所有权

pnpm 调用链必须进入官方 Velox CLI：

```text
pnpm dev
  → velox dev
  → swift build
  → VeloxBundler
  → Cleaning Dev.app/Contents/MacOS/CleanSpaceDesktop

pnpm build:app:dev
  → Node profile runner
  → velox build --debug --bundle

pnpm build:app
  → velox build --bundle
```

Node 不实现 Swift build、Velox bundling、Vite dev watcher 或 bundle 目录结构。Node 只用于
Velox hook 中尚未被上游 dylib bundling 覆盖的窄适配。

macOS Development runner 使用 `swift build`，随后运行 `beforeBundleCommand`、`VeloxBundler`
和 ad-hoc signing。它不得修改或再次运行 `.build/debug/<target>`；只启动 Bundle 内副本。

### 3. Bundle config 真实性

Velox Bundler 必须直接序列化调用方传入的 effective config 到
`Contents/Resources/velox.json`。修复落地后删除以下迁移适配：

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

`velox dev` 启动真正 `.app`。图标只由 Bundle `Info.plist` 的 `CFBundleIconFile` 与
`Contents/Resources/AppIcon.icns` 管理。不得保留运行时 AppKit 图标补丁。

### 5. 运行时 config

`DesktopApp` 使用 `VeloxConfig.load()`：

- `velox dev` 从 `Cleaning Dev.app/Contents/Resources` 读取 effective Development config；
- `.app` 从 `Bundle.main.resourcePath` 读取自身 config。

不得用编译期 `#filePath` 回到源码目录。已安装 app 不能依赖开发机源码路径。

### 6. 单实例域

app bundle 使用 `Bundle.main.bundleIdentifier`。bundle-first dev 落地后删除 pnpm 注入的
`CLEANING_BUNDLE_IDENTIFIER`；最终 fallback 只服务非 Bundle 测试进程。

解析优先级：

1. `Bundle.main.bundleIdentifier`
2. `CLEANING_BUNDLE_IDENTIFIER`
3. `me.systembug.cleaning`

## 测试策略

1. Velox Runtime 单测：Development identity override 与 Production 基础配置不变。
2. Velox Bundler 单测：Bundle Resources 写入调用方传入的 effective config。
3. Velox CLI 单测：macOS Development launch 指向 `.app/Contents/MacOS/<target>`，工作目录为
   Bundle Resources。
4. Swift 单测：bundle identifier 优先与 Production 最终 fallback。
5. 契约检查：两个 `.app` 的 `Info.plist`、Resources config、icon、dylib load path 与签名。
6. 真实验收：`pnpm dev` 进程路径位于 `Cleaning Dev.app/Contents/MacOS`；Dock 使用源图标；
   Development 与 Production 并行；重复启动只唤醒同 variant。

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| profile 配置漂移 | 每次从 canonical config 纯函数派生 |
| 两个构建并发覆盖 | profile config 写独立 `.build/velox-profile/development` |
| Velox Bundler 复制错误 config | bundle 后窄覆盖；上游修复后删除 |
| custom plist 覆盖身份 | 删除三个硬编码身份键 |
| Development 与 Production 抢同一锁 | `development.identifier` 写入真实 Bundle |
| 修改 Mach-O 后签名失效 | bundle 完成后最终签名并严格验证 |
| fork branch 漂移 | Cleaning SwiftPM dependency 固定已验证 revision |

## 实施任务

1. `TASK-015-01`：Development profile config 派生与 Node 单测。
2. `TASK-015-02`：pnpm → Velox CLI 命令与 bundle config 修正。
3. `TASK-015-03`：运行时 config 加载与单实例身份解析。
4. `TASK-015-04`：双 bundle 构建、签名、并行运行与同 variant 单实例验收。
5. `TASK-015-05`：`luban-ws/velox` 实现 macOS bundle-first dev 与 effective config bundling。
6. `TASK-015-06`：Cleaning 固定 Velox fork revision，删除 bare executable 图标与身份补丁。

## 验收标准

1. `pnpm dev` 启动路径为
   `Cleaning Dev.app/Contents/MacOS/CleanSpaceDesktop`，不是 `.build/debug/CleanSpaceDesktop`。
2. Debug 输出 `Cleaning Dev.app` / `me.systembug.cleaning.dev`。
3. Release 输出 `Cleaning.app` / `me.systembug.cleaning`。
4. 两个 bundle 的 Resources config 与 `Info.plist` 身份一致。
5. 两个 app 可同时运行。
6. 每个 variant 各自保持单实例。
7. Dock 图标来自 Bundle `AppIcon.icns`，不存在运行时图标补丁。
8. `otool -L` 无开发机绝对 dylib 路径。
9. `codesign --verify --deep --strict` 通过。
10. Velox、Swift、pnpm 相关测试通过。

## 回滚

删除 profile runner与相关 pnpm 命令，恢复 `DesktopApp` 的 Production fallback。Production canonical config 与 `Cleaning.app` 不迁移、不改名。

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-27 | 用户批准 Development / Production 独立 app 名称、bundle identifier 与并行运行 |
| 2026-07-28 | 用户批准使用 `luban-ws/velox` 实现 macOS bundle-first dev，并由 Cleaning 固定该 fork |
