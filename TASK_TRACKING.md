# CleanSpace 任务跟踪（对接 RFC）

## 对 Agent 与贡献者的约束（强制）

- 本文与 **`ROADMAP.md`** 为**单一真相来源**：任务 **ID**、**状态**、**备注** 与路线图 **顺序/状态** **必须一致**；不得在未更新本文与路线图的情况下宣称 RFC 完成、合并 PR 或丢弃任务 ID。
- **实施优先级**以 **`ROADMAP.md`** 的 **顺序** 列为准（**RFC 009 先于 RFC 005/006**）；本节按 **RFC 编号** 排列，便于查找。
- 任何任务变更：**同时**更新 **`ROADMAP.md`**（若影响范围/状态）与对应 **RFC 头部状态**。

与 **`ROADMAP.md`** 中的 RFC 顺序一致；完成或变更时请同步更新路线图与 RFC 文档头部状态。

## 字段说明

| 列 | 含义 |
|----|------|
| **ID** | 稳定引用符，便于在提交说明中写法如 `TASK-001-03`。 |
| **RFC** | 对应 RFC 编号。 |
| **任务** | 可验收的一条工作项。 |
| **状态** | `待办` / `进行中` / `已完成` / `阻塞`。 |
| **备注** | PR、issue、说明或依赖。 |

---

## RFC 001 — CCleaner 式清理规范

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-001-01 | 规则数据模型与内置 `cleaning-rules.json` 加载 | 已完成 | `CleaningRule` + `CleaningRulesLoader` + SPM 资源 |
| TASK-001-02 | 用户规则 `user-cleaning-rules.json` 与内置合并（同 id 覆盖） | 已完成 | `~/Library/Application Support/CleanSpace/` |
| TASK-001-03 | 规则清理 UI：分类列表、扫描、勾选、确认与结果反馈 | 已完成 | `ContentView` 规则工作区 |
| TASK-001-04 | Docker 辅助：Desktop 目录体积、`docker system df`、预设命令流 | 已完成 | `DockerSpecialCleanService` 等 |
| TASK-001-05 | 磁盘视图：卷选择、已用/可用、顶层目录扫描与「未由扫描计入」对账说明 | 已完成 | `VolumeScannerService`、`VolumeDiskAccounting` |
| TASK-001-06 | 单元测试：规则 JSON 解码、卷对账纯函数 | 已完成 | `CleanSpaceTests` |
| TASK-001-07 | 内置规则覆盖 RFC 所列浏览器/系统/Docker/AI 路径 | 已完成 | 跟踪改挂 **[RFC 002](.spec/rfc/completed/002-builtin-rules-catalog-parity.md)** |
| TASK-001-08 | 清理预演 / 仅列出将删除项 | 已完成 | 规则页「预览」已实现；增强项另议 |
| TASK-001-09 | 完全磁盘访问等权限引导 | 已完成 | 跟踪改挂 **[RFC 004](.spec/rfc/completed/004-full-disk-access-onboarding.md)** |
| TASK-001-10 | 用户规则 YAML 与「自定义规则」设置页 | 待办 | 跟踪改挂 **[RFC 005](.spec/rfc/005-user-rules-yaml-and-settings-editor.md)** |
| TASK-001-11 | 规则导入/导出 | 待办 | 跟踪改挂 **[RFC 006](.spec/rfc/006-rules-import-and-export.md)** |
| TASK-001-12 | 操作审计（撤销另开 RFC） | 待办 | 跟踪改挂 **[RFC 007](.spec/rfc/007-post-clean-audit-log.md)** |

---

## RFC 002 — 内置规则目录对齐

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-002-01 | 维护 [`appendix-002-rfc001-rules-matrix.md`](.spec/rfc/appendix-002-rfc001-rules-matrix.md)（RFC 001 ↔ `id`）；每 PR 补行或更新状态 | 已完成 | **唯一**矩阵路径，见 RFC 002 |
| TASK-002-02 | 按矩阵补全 Safari / Firefox / Edge / Arc / Brave / Opera 等缺项规则 | 已完成 | 与 003 衔接 Chromium 多 profile |
| TASK-002-03 | 规则 JSON 解码测试：新增合法片段 + **故意损坏片段**失败路径 | 已完成 | RFC 002 验收 |

---

## RFC 003 — Chromium 多 Profile

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-003-01 | 设计并实现 profile 发现与路径展开，与扫描/清理/预览一致 | 已完成 | 见 RFC 003 正文 |
| TASK-003-02 | 临时目录夹具单测：多 profile、**零 profile**、非目录子项、**逃逸 symlink** | 已完成 | RFC 003 验收 |

---

## RFC 004 — 完全磁盘访问引导

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-004-01 | 主触发（errno/API 拒绝 + 已知前缀）；辅触发；**禁止**仅靠「体积为 0」；共用提示组件（L10n） | 已完成 | `FullDiskAccessGuidance` + `FullDiskAccessBanner`；含诚实文案 |
| TASK-004-02 | 可选：跳转系统设置中完全磁盘访问页 | 已完成 | Ventura+ `PrivacySecurity.extension` URL，旧 pane 回退 |
| TASK-004-03 | 回归：无拒绝错误时不得仅因体积 0 反复弹窗 | 已完成 | `FullDiskAccessGuidanceTests`；手工：关 FDA 账号扫受限路径 |

---

## RFC 005 — 用户规则 YAML 与编辑器

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-005-01 | JSON 用户规则 + 设置内列表/编辑/保存；**保存后内存重载**；错误定位（字段路径/行号） | 待办 | **依赖 TASK-009-01**；`disableBuiltinIds` 语义见 RFC 005 |
| TASK-005-02 | （可选子阶段）SPM YAML 与 `user-cleaning-rules.yaml`；与 JSON 并存时加载顺序见 RFC 005 | 待办 | 依赖 TASK-009-01 |

---

## RFC 006 — 导入与导出

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-006-01 | **v1 导出**：UTF-8 **JSON 数组**（RFC 006 定案） | 待办 | YAML 导出非 v1 |
| TASK-006-02 | 导入：009 校验 → 预览 → **默认保守合并**（冲突 id 跳过）；高级「覆盖冲突」单独入口 | 待办 | **依赖 TASK-009-01**；冲突矩阵单测见 RFC 006 |

---

## RFC 007 — 审计日志

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-007-01 | 追加写日志与轮转/大小上限策略；**写入失败**：计数 + os_log + 设置/关于可观测 | 待办 | 不得静默丢失败 |
| TASK-007-02 | （可分阶段）只读「最近操作」UI 与清空；Phase 1 无 UI 时须告知日志路径 | 待办 | |
| TASK-007-03 | 单测：dry-run **不写**审计；日志目录不可写时清理仍完成且失败可观测 | 待办 | RFC 007 验收 |
| TASK-007-04 | 默认仅记 rule `id`；完整路径为可选设置并附隐私说明 | 待办 | |

---

## RFC 008 — Docker 路径重置向导

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-008-01 | 内置 schema：`hiddenFromRulesList`；Docker §3.2 规则隐藏于常规列表 | 待办 | RFC 008 定案 |
| TASK-008-02 | 多步向导 UI 与 L10n（短文案、后果明确） | 待办 | 与常规规则/向导隔离 |
| TASK-008-03 | 执行删除与审计联动 | 待办 | 见 TASK-007-* |

---

## RFC 009 — 用户规则安全与排除

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-009-01 | **单一校验模块**：路径规范解析（含 symlink 逃逸拒绝）；**argv[0] 白名单 + token 子命令表**；不在白名单则禁止保存 | 已完成 | `UserRuleValidator` + 用户规则加载器接线；保存/导入在 005/006 复用同入口 |
| TASK-009-02 | 单测：越界路径、逃逸 symlink、非法命令、合法 `~/Library/...` | 已完成 | `UserRuleValidatorTests` |
| TASK-009-03 | 文档：argv 白名单与子命令表扩展流程 | 已完成 | `docs/user-rule-command-whitelist.md` |
| TASK-009-04 | （可选）`exclude` 或按大小阈值清理 — Phase 2 决策记录 | 已完成 | 明确推迟，不属于 RFC 009 当前完成口径；后续需要时另开任务并补扫描/预览/清理一致性测试 |

---

## RFC 010 — 规则工作区 UI 与协作索引

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-010-01 | RFC 010 正文：工具栏策略、扫描列表、AGENTS / Paul Hudson、验收标准 | 已完成 | `.spec/rfc/completed/010-rules-workspace-ui-hig-and-collaboration.md` |
| TASK-010-02 | 移除规则页重复工具栏；进度并入 `CSRulesCleanWorkflowCard` | 已完成 | `ContentView` + `WorkspaceChrome` |
| TASK-010-03 | `RulesScanListRow` + 表列度量共用 + L10n / a11y | 已完成 | `Rules/` 下源文件 |
| TASK-010-04 | `AGENTS.md` 合并结构 + `paul-hudson.md` + `/swiftui` | 已完成 | 根目录与 `docs/persona/` |
| TASK-010-05 | （可选）应用菜单命令与操作卡共享动作 | 待办 | 见 RFC 010「后续可选」 |

---

## RFC 011 — Rules Studio 自定义规则编辑器

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-011-01 | Rules Studio 数据模型与 JSON 读写适配 | 待办 | 不引入 YAML |
| TASK-011-02 | 独立窗口、toolbar、三栏布局 | 待办 | macOS 原生控件 |
| TASK-011-03 | 字段化编辑器：基础字段、dir、command | 待办 | 按 type 渐进披露 |
| TASK-011-04 | RFC009 校验接线与字段错误映射 | 待办 | 保存前阻断 |
| TASK-011-05 | 保存后 reload 通知与规则工作区刷新 | 待办 | 无需重启 |
| TASK-011-06 | L10n、单测、手动验收记录 | 待办 | en + zh-Hans |

---

## 新增 RFC 时

在 **`ROADMAP.md`** 追加一行并新开一节 `## RFC NNN — …`，复制上表头后填任务行。
