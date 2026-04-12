# CleanSpace 任务跟踪（对接 RFC）

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
| TASK-001-07 | 内置规则覆盖 RFC 所列浏览器/系统/Docker/AI 路径（持续补全与校验） | 进行中 | 按 RFC 表格逐项核对 `cleaning-rules.json` |
| TASK-001-08 | 清理预演 / 仅列出将删除项（可选） | 待办 | RFC「安全」 |
| TASK-001-09 | 完全磁盘访问等权限引导（若需遍历受保护路径） | 待办 | RFC「权限」 |
| TASK-001-10 | 用户规则 YAML 与可选「自定义规则」设置页 | 待办 | RFC「后续」 |
| TASK-001-11 | 规则导入/导出（单条或整份） | 待办 | RFC「共享与复用」 |
| TASK-001-12 | 操作审计或撤销（若单独 RFC 则改挂新 ID） | 待办 | RFC「实现要点」脚注 |

---

## 新增 RFC 时

在 **`ROADMAP.md`** 追加一行并新开一节 `## RFC NNN — …`，复制上表头后填任务行。
