# CleanSpace 路线图（RFC 顺序与状态）

## 对 Agent 与贡献者的约束（强制）

- **`ROADMAP.md`（本文件）** 与 **`TASK_TRACKING.md`** 为实施优先级与交付状态的**权威来源**；与 RFC 正文冲突时，**先对齐本表与任务表**，再修订 RFC。
- 变更范围、状态或完成度时：**必须**同时更新本表、**`TASK_TRACKING.md`**、对应 RFC 头部 `**状态**`，不得只改代码或只改 RFC。
- 认领/关闭工作项时：**必须**在 **`TASK_TRACKING.md`** 中更新对应 **ID** 的状态与备注。

本文件与 **`TASK_TRACKING.md`**、**`.spec/rfc/`** 下的 RFC 正文配合使用：

- **路线图（本文件）**：RFC 的**优先级顺序**、**生命周期状态**、阶段划分。
- **任务跟踪**：可执行的细项、负责人占位、与 PR/提交的对应关系。
- **RFC 正文**：需求、路径、风险与方案细节；头部 **状态** 应与下表同步更新。

## 状态说明

| 状态 | 含义 |
|------|------|
| **草案** | 正在撰写或范围未冻结。 |
| **评审中** | 可评审；待结论。 |
| **已批准** | 范围冻结，可按任务跟踪实施。 |
| **实施中** | 已有代码落地，尚未达到 RFC 验收口径。 |
| **已完成** | 达到当前 RFC 约定的验收范围（可移入 `.spec/rfc/completed/` 若日后启用归档目录）。 |
| **已搁置** | 明确不做或无限期推迟（需简短原因）。 |

## RFC 顺序与状态（权威表）

按**实施优先级**排列；新增 RFC 时递增编号并追加一行。

| 顺序 | RFC | 标题 | 路线图状态 | 备注 |
|------|-----|------|------------|------|
| 1 | [001](.spec/rfc/001-ccleaner-style-cleaning-spec.md) | CCleaner 式清理规范（路径、规则、安全边界） | 实施中 | 规范母本；缺口拆至 002–009 |
| 2 | [002](.spec/rfc/completed/002-builtin-rules-catalog-parity.md) | 内置规则与 RFC 001 目录对齐 | 已完成 | 对照矩阵固定：[appendix-002](.spec/rfc/appendix-002-rfc001-rules-matrix.md)；补全 `cleaning-rules.json` |
| 3 | [003](.spec/rfc/completed/003-chromium-profile-discovery.md) | Chromium 多 Profile 路径解析 | 已完成 | 依赖 002 浏览器规则基线 |
| 4 | [004](.spec/rfc/completed/004-full-disk-access-onboarding.md) | 完全磁盘访问与受限路径引导 | 已完成 | 主触发须 errno/API；`FullDiskAccessBanner`；手工关 FDA 账号可复验 |
| 5 | [009](.spec/rfc/completed/009-user-rule-safety-and-exclusions.md) | 用户规则安全边界与排除/阈值 | 已完成 | 校验模块 + 用户规则加载器接线 + 单测 + 白名单文档已落地；`exclude`/`minSizeBytes` 推迟到 Phase 2；005/006 保存/导入复用同入口 |
| 6 | [005](.spec/rfc/005-user-rules-yaml-and-settings-editor.md) | 用户规则 YAML 与设置内编辑器 | 草案 | 调用 009；JSON 必选、YAML 可选；保存后内存重载 |
| 7 | [011](.spec/rfc/011-rules-studio-custom-rules-editor.md) | Rules Studio：自定义规则编辑器详细 UI | 草案 | RFC 005 UI 细稿；JSON 表单优先，YAML 延后 |
| 8 | [006](.spec/rfc/006-rules-import-and-export.md) | 规则导入与导出 | 草案 | 依赖 009 + 005；**v1 导出 UTF-8 JSON 数组**；默认合并保守（冲突 id 跳过） |
| 9 | [007](.spec/rfc/007-post-clean-audit-log.md) | 清理操作审计日志 | 草案 | 可分阶段；写入失败须可观测（计数/os_log/设置） |
| 10 | [008](.spec/rfc/008-docker-desktop-path-reset.md) | Docker Desktop 路径级重置向导 | 草案 | `hiddenFromRulesList`；与日常 prune 隔离 |
| 11 | [010](.spec/rfc/010-rules-workspace-ui-hig-and-collaboration.md) | 规则工作区：扫描列表/预览/确认/清理 **详细 UI**（RFC 内第二部分）+ 协作索引 | 实施中 | TASK-010-06～09 已落地；1120×792 实机通过，840×700 新 bundle 已生成，待下次 Dev 进程冷启动验收 |
| 12 | [012](.spec/rfc/012-ui-polishing-and-hig-compliance.md) | UI 抛光与 macOS HIG 自适应合规 | 实施中 | 针对沉浸式标题栏遮挡、网格自适应与矢量进度环的打磨细节 |
| 13 | [013](.spec/rfc/completed/013-velox-ui-shell-migration.md) | Desktop Shell 迁移（Velox + React + 模块化 Swift） | 已完成 | `apps/desktop` 默认；G3/G4 见 `pnpm run:swiftui`；AppIcon 单源同步 |
| 14 | [014](rfc/completed/014-single-instance-desktop-lifecycle.md) | Velox Desktop 单实例生命周期 | 已完成 | 核心已落地；单实例内核文件锁判定、分布式唤醒与 SwiftUI 辅助并存手验全部完成 |
| 15 | [015](rfc/completed/015-velox-development-production-isolation.md) | Velox Development / Production 应用隔离 | 已完成 | `luban-ws/velox` bundle-first dev；Dev/Prod 并行与同 variant 单实例验收通过 |

## 阶段概览（与 RFC 001 对齐）

| 阶段 | 目标 | 关联 |
|------|------|------|
| **Phase A — v1 核心** | 内置 JSON 规则、按类展示、扫描/清理、Docker 与磁盘辅助视图、用户规则文件合并 | RFC 001「v1（当前）」 |
| **Phase B — 体验与权限** | 完全磁盘访问说明、高风险操作一致确认、扫描口径与系统「已用」对账（应用内说明） | RFC 001 风险与权限 |
| **Phase C — 可扩展** | 用户规则、YAML/编辑器、导入/导出（与 Phase D 中 RFC 005/006/009 对应） | 实施顺序以本表 **顺序** 列为准：**009 先于 005/006**；009 未就绪前不默认开放文件导入 |
| **Phase D — 缺口闭合** | RFC **002–009**：内置对齐、多 profile、权限引导、审计、Docker 路径重置、用户规则安全与编辑/导入 | 范围覆盖 002–009；**009 优先于 005/006** 见上表顺序列 |

## 维护约定

1. 变更 RFC 范围或状态时：**同时**更新本表、对应 RFC 头部 `**状态**：…`，并在 **`TASK_TRACKING.md`** 中增删或勾选任务（**不得遗漏**）。
2. 完成某一 RFC 的约定交付后：将路线图状态改为 **已完成**，任务表对应项标为完成，并考虑将 RFC 文件移至 `.spec/rfc/completed/`（若目录已创建）。
3. **顺序列**表示建议实施先后；与 RFC 数字编号无关时**以本表顺序为准**（例如 009 列为 5，优先于 005/006）。
