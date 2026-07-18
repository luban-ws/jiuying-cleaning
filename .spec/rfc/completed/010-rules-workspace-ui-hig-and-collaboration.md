# RFC 010：规则工作区 — 基于规则的扫描列表、预览、确认与清理（详细 UI 设计）

**状态**：已完成（**本文含规范性 UI 细稿**；主验收已落地；可选应用菜单共享动作见 TASK-010-05）  
**创建日期**：2026-04-12  
**作者**：CleanSpace  

**权威说明**：规则清理详情列的 **布局、组件、尺寸、模态与无障碍** 仅以 **本文第二部分** 为准。Apple 官方对照链接见 `docs/macos-swiftui-references.md`（非 UI 细稿）。修改规则页 UI 规范时 **只改本 RFC**。

---

## 第一部分：摘要、决策与协作

### 1.1 摘要

- **平台**：macOS 15+（Sequoia）；详情区对齐系统「设置」类应用：`NavigationSplitView`、grouped `Form`、`Material`、`.help()`。
- **单一主操作面**：分析 / 预览 / 运行清理仅在 **`CSRulesCleanWorkflowCard`**；规则主列表页 **无** 重复 `primaryAction` 工具栏三按钮。
- **行为语义**：**「分析」** 对 **全部已加载规则** 扫描（更新大小列与图表数据）；**「预览」「运行清理」** 仅针对 **已勾选** 规则。
- **协作**：`AGENTS.md` 基线 + Persona；`/swiftui` 与 `docs/persona/paul-hudson.md`。

### 1.2 与 RFC 001 的边界

| RFC 001 | 本 RFC 010 |
|---------|------------|
| 可清理路径、风险、安全边界 | **如何**在界面呈现勾选、扫描、预览、确认与结果 |
| 「删什么」 | 「在哪点、什么顺序、什么控件」 |

### 1.3 冻结的产品决策（交互语义）

| ID | 决策 |
|----|------|
| D1 | 规则主列表页 **不得** 使用与流程卡三动作重复的 `ToolbarItemGroup(placement: .primaryAction)`。 |
| D2 | 根 `NavigationSplitView` 详情侧可保留 `toolbarBackground` / `toolbarBackgroundVisibility`。 |
| D3 | 预览 Sheet 可使用 `confirmationAction`（如「完成」）。 |
| D4 | **分析** = 全量规则扫描，**不**依赖勾选。 |
| D5 | **预览 / 运行清理** = 仅勾选集。 |
| D6 | 详情区垂直顺序见 **第二部分 §2.3**；变更顺序须同步本文与实现。 |
| D7 | 运行清理前 **确认 Alert**；完成后 **结果 Alert**。 |

### 1.4 协作索引（AGENTS / Persona）

- `AGENTS.md`：黄金法则、工程基线、Persona 表、快捷指令（含 `/swiftui`）。
- `docs/persona/paul-hudson.md`：SwiftUI 实现协作参考。

---

<a id="detailed-ui-spec"></a>

## 第二部分：详细 UI 设计（规范性）

本节为 **规则基于扫描列表、预览、确认与清理** 的完整界面规格；与 `CleanSpaceKit` 实现对照验收。

### 2.1 范围

| 包含 | 不包含 |
|------|--------|
| 侧栏「规则清理」**详情列** 布局与组件 | 「磁盘」「Docker」工作区 |
| 预览 Sheet、确认/结果 **Alert** 结构 | 像素级 Figma；独立品牌色体系 |
| **布局常量名**（与代码一致） | — |

### 2.2 信息架构

```
NavigationSplitView
├── Sidebar：… / 规则清理 / …
└── Detail
    └── NavigationStack
        ├── navigationTitle：规则清理（L10n）
        ├── navigationSubtitle（可选）：已选 n / 共 m 条
        └── DetailScaffold → grouped Form（§2.3～§2.8）
```

- **内容最大宽**：`CS.detailContentMaxWidth` = **840 pt**，水平居中。
- **边距**：水平 `CS.detailHorizontalPadding` = **24 pt**；垂直 `CS.detailVerticalPadding` = **20 pt**（`contentMargins`）。
- **工具栏**：规则主列表页 **禁止** 与流程卡重复的 primaryAction 三图标（D1）。

### 2.3 详情区纵向结构（自上而下）

**唯一权威顺序**；对应 `RulesWorkspaceView` 内 `Form` Section 顺序。

```
┌─────────────────────────────────────────────────────────────┐
│ 2.3.1 概览卡 CSRulesOverviewPanel                            │
├─────────────────────────────────────────────────────────────┤
│ 2.3.2 分步说明 Section（rules.flow.section_title / steps）   │
├─────────────────────────────────────────────────────────────┤
│ 2.3.3 流程卡 CSRulesCleanWorkflowCard（扫描·预览·清理）      │
├─────────────────────────────────────────────────────────────┤
│ 2.3.4 图表区（可选：存在路径类正扫描体积时）                  │
├─────────────────────────────────────────────────────────────┤
│ 2.3.5 按分类：RulesScanListRow 或 BrowserRulesTableBlock     │
└─────────────────────────────────────────────────────────────┘
```

### 2.4 视觉与材质 Token

| Token | 值 / 说明 |
|-------|-----------|
| `CS.cornerHero` | **16 pt**，`continuous` |
| `CS.cornerPanel` | **14 pt** |
| `CS.cornerSmall` | **10 pt** |
| 概览 / 流程卡 | `Material.regular`，内边距 **18 pt** |
| 图表卡 | `Material.regular`，内边距 **16 pt** |
| 卡片描边 | `Color.primary` **6%～8%** opacity，**1 pt** |
| 强调 | `Color.accentColor` |
| 破坏性主按钮 | `borderedProminent` + `.tint(.red)` |
| 字体角色 | 标题 `headline`；说明 `subheadline` + `secondary`；辅助 `caption` / `tertiary` |

### 2.5 组件规格

#### 2.5.1 概览卡（CSRulesOverviewPanel）

| 元素 | 规格 |
|------|------|
| 图标 | `checklist.checked`，`largeTitle`，hierarchical |
| 标题 | `L10n.Rules.overviewTitle`，`headline` |
| 副文 | `L10n.Rules.overviewBlurb`，`subheadline`，`secondary` |
| 芯片 | 三枚：总数 / 已选 / 已测有体积条数；胶囊底；有数据或已选可用 accent 浅底 |

#### 2.5.2 分步说明 Section

| 元素 | 规格 |
|------|------|
| Header | `L10n.Rules.flowSectionTitle`，`subheadline.weight(.semibold)` |
| Body | `L10n.Rules.flowSteps`，`subheadline`，`secondary`，多行左对齐；可选 `textSelection(.enabled)` |

#### 2.5.3 流程卡（CSRulesCleanWorkflowCard）— **扫描 / 预览 / 清理主控**

| 区域 | 规格 |
|------|------|
| 标题区 | `actionTitle` `headline`；`actionBlurb` `subheadline` `secondary` |
| 可回收体积 | 标签 `actionRecoverableLabel` `caption` `secondary`；数值 **30 pt semibold rounded**，`monospacedDigit`；占位或需分析时 `secondary`，有可强调体积时 `accentColor` |
| 辅文 | `caption` `tertiary`（选中数、路径类/命令类计数） |
| **扫描/清理进行中** | 主按钮行 **上方**：`ProgressView` `.small` + `L10n.Rules.scanning` / `cleaning`，`subheadline` `secondary`；`accessibilityElement(children: .combine)` |
| **主按钮行（三等分）** | **分析**：`borderedProminent` `large`，`Label`+gauge 图标，`.help(helpScan)`；**预览**：`bordered` `large`，`.help(helpDryRun)`；**运行清理**：`borderedProminent` `large` **red**，`.help(helpClean)` |
| 次操作 | 全选 / 全不选：`plain` + accent，`subheadline.medium` |

**启用规则**：

- **分析**：`rulesNonEmpty` 且 **非** `isScanning`。
- **预览**：`selectedCount > 0` 且 **非** `isCleaning`。
- **运行清理**：`selectedCount > 0` 且 **非** `isCleaning`。

#### 2.5.4 图表区（CSChartCard + RulesScanChartBlock）

| 元素 | 规格 |
|------|------|
| 标题 | `Label` + `chart.pie.fill`，`headline`，`titleAndIcon` |
| 图体最小高度 | **260 pt** |

#### 2.5.5 扫描列表行（RulesScanListRow）— **非浏览器分类**

| 区 | 规格 |
|----|------|
| 交互 | `Toggle`，`toggleStyle(.checkbox)` |
| 主列 | 规则名 `body`；警告 `caption` `secondary`，多行 |
| **大小列** | 固定 **108 pt**（`RulesScanListLayoutMetrics.scanColumnWidth`），`caption`，`monospacedDigit`；路径规则 `.help` = `L10n.Rules.listHelpScanColumn` |
| **风险列** | 固定 **56 pt**（`riskColumnWidth`），`RuleRiskChip` |
| `listRowInsets` | 约 **上下 6**、**左 4 右 8**（全表一致） |

#### 2.5.6 浏览器分类表（BrowserRulesTableBlock）

| 列 | 宽度 / 行为 |
|----|-------------|
| Clean | **52 pt**；Toggle `labelsHidden`；`accessibilityLabel` = 规则名；`accessibilityHint` = `L10n.Rules.listA11yToggleHint` |
| Item | min **160** / ideal **220** |
| Size | **108 pt**；路径格 `.help` 同 2.5.5 |
| Risk | **56 pt** |
| 样式 | `tableStyle(.inset(alternatesRowBackgrounds: true))` |
| 最小高度 | `min(380, max(120, 52 + rowCount × 32))` pt |

### 2.6 模态：预览（演练）与确认/结果

#### 2.6.1 预览 Sheet（RulesDryRunSheet）

- `NavigationStack` + grouped `Form`；`navigationTitle` = `L10n.Rules.dryRunSheetTitle`。
- 内容：免责声明 + 按规则分 Section 列出路径或命令（等宽可选中）。
- 工具栏：**仅** `confirmationAction` 完成按钮（`dismiss`）。
- **最小尺寸**：`minWidth` **440**，`minHeight` **380**（可按内容微调，须保持可读）。

#### 2.6.2 确认清理 Alert

- `isPresented` 绑定「运行清理」前置状态。
- 标题：`L10n.Rules.alertConfirmTitle`。
- 按钮：**取消**（`Common.cancel`）+ **运行清理**（destructive，执行 `performClean`）。
- **message**：动态（低风险条数 / 含中高风险提示），来自既有 `L10n` 逻辑。

#### 2.6.3 结果 Alert

- 标题：`L10n.Rules.alertResultTitle`。
- 按钮：`Common.ok`。
- **message**：多行清理结果（每规则一行格式由 `L10n` 定义）。

### 2.7 空状态

- `ContentUnavailableView`：`rules.empty.title` / `rules.empty.description`，`doc.text`。
- 最小高度约 **280 pt**，置于 `DetailScaffold` 内居中。

### 2.8 无障碍（验收清单）

- [ ] 流程卡三主按钮均有 `.help`（`L10n.Rules.helpScan` / `helpDryRun` / `helpClean`）。
- [ ] 列表与表：Toggle `accessibilityHint` = `listA11yToggleHint`；表内无标签 Toggle 须有 `accessibilityLabel`（规则名）。
- [ ] 扫描/清理进度行 VoiceOver 可理解（合并或显式标签，须实测）。
- [ ] 用户可见字符串 **仅** `L10n` + `en` / `zh-Hans` `Localizable.strings`。

### 2.9 流程图（Mermaid）

**与 §2.3～§2.6 冲突时以表格为准。**

**图 A — 详情区纵向区块**

```mermaid
flowchart TD
  subgraph Detail["详情区 · NavigationStack · grouped Form"]
    O[2.3.1 概览卡]
    F[2.3.2 分步说明]
    W[2.3.3 流程卡]
    C{路径类有正扫描体积?}
    G[2.3.4 图表]
    L[2.3.5 列表或浏览器表]
    O --> F --> W --> C
    C -->|是| G --> L
    C -->|否| L
  end
  S[侧栏 · 规则清理] --> Detail
```

**图 B — 扫描 → 勾选 → 预览 → 确认 → 清理 → 结果**

```mermaid
flowchart LR
  subgraph Scan["扫描（全量）"]
    A1[分析] --> A2[流程卡进度]
    A2 --> A3[scanRule 逐条]
    A3 --> A4[大小列与图表]
  end
  subgraph Clean["清理路径（仅勾选）"]
    B1[勾选规则] --> B2[可选 预览 Sheet]
    B2 --> B3[运行清理]
    B3 --> B4[确认 Alert]
    B4 --> B5[执行清理]
    B5 --> B6[结果 Alert]
  end
  Scan -.->|可交错| B1
```

### 2.10 实现映射

| 规格对象 | 代码路径 |
|----------|----------|
| `DetailScaffold` / `CS` | `AppChrome.swift` |
| `RulesWorkspaceView` Form | `ContentView.swift` |
| 概览 / 流程卡 | `WorkspaceChrome.swift` |
| 列表行 | `Rules/RulesScanListRow.swift` |
| 浏览器表 | `Rules/BrowserRulesTableBlock.swift` |
| 文案 | `Localization/L10n.swift`，`Resources/*/Localizable.strings` |

**变更流程**：改布局、尺寸或顺序 → **先改本文第二部分** 与 Mermaid；改「分析是否全量」等语义 → 同步 **§1.3 冻结决策**。

---

## 第三部分：验收标准

1. 实现与 **第二部分** 无冲突（顺序、列宽、按钮启用、Sheet/Alert、§2.8 清单）。
2. 满足 **§1.3 D1–D7**。
3. `cd app && swift build && swift test` 通过；`scripts/check-swift-ui-l10n.sh`（若安装 `rg`）通过。
4. `AGENTS.md` 指向本 RFC；含 Paul Hudson 与 `/swiftui`。

---

## 第四部分：相关文件与后续可选

| 类型 | 路径 |
|------|------|
| Apple HIG / SwiftUI 索引 | [docs/macos-swiftui-references.md](../../../docs/macos-swiftui-references.md) |
| 协作 | `AGENTS.md`，`docs/persona/paul-hudson.md` |

**后续可选**：应用菜单/快捷键（仍遵守 D1）；单卡合并概览+流程等视觉优化 — 须 **先改本文第二部分** 再改代码。

---

## 修订历史

| 日期 | 说明 |
|------|------|
| 2026-04-12 | 多轮迭代（工具栏、列表、L10n、Mermaid、Persona 等） |
| 2026-04-12 | 曾误拆「RFC 仅决策 / design 仅细稿」引发双源 |
| 2026-04-12 | **纠正**：**详细 UI 设计全部并入本文第二部分**；RFC 为单一权威 |
| 2026-04-12 | 删除 `docs/design/`；HIG 索引迁至 `docs/macos-swiftui-references.md` |
